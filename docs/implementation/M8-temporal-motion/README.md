# M8: Temporal 再利用、Motion Blur、動画向けの Stylization

目標: 動画（連番とカメラ・物体・ライトの動き）で、ちらつかずに安定した絵を、同じ GPU 時間でより少ないサンプルから作る。Temporal 再利用と Motion Blur を入れ、輪郭線・顔影・髪ハイライト・ブルーム・色収差を、動画で破綻しないものとして入れる。
依存: M1〜M7（特に M5 の差分更新と ReSTIR、M2 の Stylization と PostProcess、M6 の Blender 連携、M4 の Vulkan）。方針: ADR-0013 / 0015 / 0016 / 0017。要件: REQ-ACC-005（Temporal 再利用と Motion Blur）、REQ-STY-009（輪郭・顔影・髪）、REQ-STY-011（PostProcess）、REQ-QA-003（時間的安定性）。

いまの Verion は静止画だけで、時刻・アニメーション・Motion Vector・シャッターの仕組みがコードにない。そのため順序は「動画を測る土台 → 時刻の導入 → Motion Vector → Temporal 再利用 → Motion Blur → Stylization の動画対応 → 連携 → 評価」とする。M7 と同じく、測った結果が「効かない」なら、その機能は無効のまま理由を ADR に記録して終える。

## 表

| # | 項目 | REQ | 状態 |
|---|------|-----|------|
| 1 | 評価の土台: 動画の評価シーン（カメラの移動、物体の移動と回転、ライトの移動、キャラ相当の変形）と、連番を出す枠（`render-cli` の連番出力、フレームごとの EXR）。時間的安定性の指標（連続する 2 フレームを動きで再投影した差の RMS を、同じ動きの高 spp の参照と比べる。線の跳ね、Toon 境界のジャギーの点滅）と、基準（履歴なし・OIDN のみ）の値を先に記録する。`scripts/eval_video.sh`、ADR に基準値 | REQ-QA-003 / REQ-PERF-001 | 未着手 |
| 2 | 時刻の導入: フレーム `t` の状態をシーンに渡す方式を決める（Camera・Transform・変形メッシュ・ライト・材質のフレームごとの値と、シャッターの開閉の時刻）。差分更新（`Changes`）はフレーム間の差分としてそのまま使い、履歴を捨てる条件（ADR-0017）を「見た目が変わったか」から「動きを再投影できるか」に広げる。ADR を書く | REQ-CORE-001 / REQ-ACC-003 | 未着手 |
| 3 | Motion Vector AOV: 一次ヒットの点を前フレームの画面位置に投影する（Metal と Vulkan で同じ Slang）。Depth・Normal・Object ID・Material ID は既存。シェーダー側の前フレームの Camera と Transform の保持、`aov.slang` への追加、EXR への出力 | REQ-ACC-005 / REQ-GPU-006 | 未着手 |
| 4 | Temporal 再利用の枠: Motion Vector・Depth・Normal・ID で再投影し、不一致（遮蔽の解除、ID の違い、法線の差）で履歴を捨てる。蓄積は指数移動平均。最初は画素の色の再投影（Viewer と連番の両方）。結果が安定しなければ以降へ進まない | REQ-ACC-005 | 未着手 |
| 5 | ReSTIR（DI・GI）の Temporal 再投影: M5 は前フレームの同じ画素と近傍 2 画素の Reservoir を使っていた。動きがあるときは Motion Vector で前フレームの画素を引き、Reservoir を再投影する。履歴の破棄条件は 4 と共通にする。M5 で分かった「フレーム間の相関による誤差の下限」が動画で許せるかを測る | REQ-ACC-002 / REQ-ACC-005 | 未着手 |
| 6 | Temporal な Denoise: OIDN は 1 枚ごとなので、連続フレームで画素の値がゆらぐ（ADR-0013）。履歴で安定させる方式（4 の再投影した履歴を OIDN の入力にする、OIDN の時間方向の入力、MetalFX の Temporal Denoise の比較）を測って決める。商用再配布の条件を確認する | REQ-ACC-005 / REQ-QA-003 | 未着手 |
| 7 | Motion Blur（物理）: シャッターの区間でレイに時刻を持たせ、Transform とカメラを補間する。変形メッシュの扱い、Metal と Vulkan の加速構造がどこまで時刻つきの instance を持てるかを、最初に小さな実験（spike）で確かめる。使えない Backend では、BLAS の時刻ごとの複製か、Motion Blur なしの扱いを選ぶ。Reference でも使える（物理の効果）。ReSTIR・Temporal は Motion Blur では Fallback する（M5 の受入条件） | REQ-ACC-005 / REQ-GPU-006 | 未着手 |
| 8 | ReSTIR PT の判断（M7 から移した。ADR-0016）: 動画での再利用の効果と、経路全体のシフト写像（再接続の条件、Jacobian）の費用を、5 の結果と並べて測り、入れるか決める。結果は REQ-ACC-002 の書き換えを伴うので、利用者に確認してから反映する | REQ-ACC-002 | 未着手 |
| 9 | NRC の動画での扱い: 編集で捨てて学習し直す（M7、ADR-0022）か、継続学習で追従するかを、動きのあるシーンで測る。評価は同画質到達時間と、フレーム間の明るさのゆらぎ（M7 の測定では全体の明るさが 1.6%、NRC なしは 0.8%）。結果が悪ければ NRC は現状のまま（既定は無効、静止画向け） | REQ-ACC-004 | 未着手 |
| 10 | 輪郭線の時間的安定性: 線の跳ね、一次ヒットの AOV が画素中心 1 本であることによる境界のジャギーの点滅（REQ-QA-003 の「Toon 境界のエイリアシング」）。時間方向の安定化（サブ画素のずらし、履歴との混ぜ）を測って選ぶ。`OutlineStyle` の最小版は M2 で済 | REQ-STY-009 / REQ-QA-003 | 未着手 |
| 11 | `FaceShadowController`（Face SDF）と `HairHighlight`: 独立した Pass、IR と glTF・Blender の変換、Lighting AOV と非物理の印。ライトとカメラを動かしても顔影が破綻せず、髪のハイライトが跳ねないこと。入力（Face SDF のテクスチャか頂点属性か、髪の接線）は要確認 | REQ-STY-009 | 未着手 |
| 12 | PostProcess: ブルームと色収差。Stylization の後段の画面空間の Pass で、非物理出力とし、Reference モードでは無効にして、EXR のメタデータに記録する（REQ-STY-011）。ブルームは動画でちらつかない（明るい画素の閾値で跳ねない）ことを 1 の指標で見る | REQ-STY-011 | 未着手 |
| 13 | 連携: Blender の連番レンダー（フレーム範囲、シャッター（Motion Blur）の設定、Cycles との比較）、Viewer の再生とカメラ移動での履歴、IPR のタイムラインのスクラブ。スイッチは既定を保守的にし、非物理の印を表示する | REQ-DCC-001 / REQ-DCC-002 / REQ-VIEW-003 | 未着手 |
| 14 | Vulkan 版（RTX 3080）: 3・4・5・7・10〜12 を同じ Slang で通す。Metal との画像一致（REQ-GPU-007）。Motion Blur の加速構造は 7 の実験の結果に従う | REQ-GPU-006 / REQ-GPU-007 | 未着手 |
| 15 | 評価（続けるかの判断）: 動画の評価シーンで、時間的安定性の指標、同画質到達時間（Temporal を使う・使わない）、追加の GPU 時間と VRAM、Reference との偏りを測る。基準を満たさない機能は、無効のまま結果を ADR に記録する | REQ-QA-003 / REQ-PERF-001 / REQ-ACC-005 | 未着手 |

## 決めてあること

- Motion Blur は物理の効果で、Reference モードでも使える。Temporal 再利用・ReSTIR・NRC・ブルーム・色収差・Temporal な Denoise は非物理で、Reference では通らない。有効なら出力に非物理の印を付ける（REQ-CORE-006、ADR-0008）
- 履歴の再利用は、鏡面・屈折・Motion Blur・DoF で Fallback する（M5 の受入条件）。ガラスを通る経路は、再利用から外す
- 差分更新の方針（ADR-0017: 編集で履歴を捨てる）は、動画では「動きとして再投影できる変化」と「捨てる変化」を分ける形に広げる（2）。材質・光源・形状の追加は、これまでどおり捨てる
- ReSTIR PT は M7 から移した判断（8）。M5 の ADR-0016 に理由がある。実装を先に決めない
- DELTA（連番の差分推定とフル再計算の結合。ArcheRender の機能化トラック）は M8 でも対象外。連番の仕組み（1・2・13）は M8 で入るが、差分推定器は別のマイルストーンで、ArcheRender の CPU 実験（S1）が基準を通ってから計画する
- M1/M2 チップは対象外。Motion Blur の加速構造は、RT 搭載の Metal（M3 以降）と Vulkan RT で調べる
- Slang で一度書き、Metal を先にする（ADR-0001、ADR-0002）。新しい依存は都度確認し、商用再配布できるものだけで `mise run deny` を通す
- 測ってから続ける。1 の基準の値と、15 の基準を満たさないときは、その機能を無効にしたまま記録する

## 要確認（利用者）

- 1 の時間的安定性の合格値（再投影差分の RMS を参照の何倍以内とするか）。最初の測定を見てから決める（REQ-PERF-003 のように仮置きにして見直す）
- 2 の入口: アニメーションを glTF の animation から読むか、Blender の連番だけにするか、両方か。Viewer の再生をどこまで作るか
- 7 の Backend 差: Vulkan RT で時刻つき instance が使えない GPU の扱い（Motion Blur を Metal だけにするか、BLAS を複製するか）
- 8 の結果の反映（REQ-ACC-002 の書き換え）
- 11 の Face SDF と髪の入力（どの形式をキャラ制作側に求めるか）
- REQ-ACC-004 に「選択式の機能。既定は無効」と明記するか（M7 から持ち越し）
- Octane との同画質到達時間の比較の時期（M5 から持ち越し。Blender 連携後に実機が要る）

## 完了条件

- [ ] カメラ・ライト・物体の移動で、ちらつきが基準より小さい。指標は 1（REQ-ACC-005、REQ-QA-003）
- [ ] Temporal 再利用が同画質到達時間を縮める、または縮まないことを実測して記録し、無効のままにする
- [ ] Motion Blur が Reference を含めて動き、Cycles と大きさが合う。Fallback の条件が守られる
- [ ] カメラ・ライト・キャラ移動で、線の跳ねと顔影の破綻が出ない（REQ-STY-009、REQ-QA-003）
- [ ] ブルーム・色収差が非物理として記録され、Reference では無効（REQ-STY-011）
- [ ] Metal と Vulkan で同じ結果になる（REQ-GPU-007）
- [ ] ReSTIR PT を入れるか、入れないかの結論が ADR にある（REQ-ACC-002）
