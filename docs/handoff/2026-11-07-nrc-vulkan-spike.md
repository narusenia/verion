# 引き継ぎ: NRC の Vulkan（RTX 3080）での速度の実験

M7 で NRC は Metal だけに入れ、Vulkan は未実装（利用者決定 2026-11-07）。「Vulkan では速くなる可能性があるか」を、本体を移植する前に確かめる小さな実験。結果が良ければ、NRC の Vulkan 版（M7 の項目 9 だったもの）を再開するか決める。悪ければ、ADR-0022 に 1 行足して閉じる。Windows の RTX 3080 が要る。M7 の他の Windows 確認は `2026-11-07-m7-windows.md`。

## 作るもの
`crates/verion-gpu-vulkan/examples/nrc_spike.rs`。Metal の `crates/verion-gpu-metal/examples/nrc_spike.rs` と同じ手順を踏む（合成の目標関数を、学習 300 ステップ、推論 512×384 件）。

- ネットワーク: `crates/verion-gpu-metal/src/nrc.rs` の `NrcNet` と同じ。初期化（ハッシュグリッドは ±1e-4、MLP は He 一様、出力の偏りは −3）、バッファ（P・G・M・V の 4 本、各 `PARAMS` 個の f32）、`cfg`（8 語: 個数、ステップ、境界の最小 xyz、境界の逆数、テーブルの学習率、MLP の学習率）をそのまま Rust に写す。語数の定数は `nrc.rs` の `LEVELS`・`TABLE`・`F`・`H` と、`shaders/include/nrc_net.slang`
- カーネル: `nrc_train`、`nrc_adam`、`nrc_infer`。SPIR-V は `crates/verion-gpu-vulkan/shaders/nrc_*.spv` にコミット済み（`mise run shaders` で再生成）。`src/shaders.rs` の `spirv()` の表にはまだ載っていないので、3 つ足す
- ディスパッチ: 3 本とも 64 スレッドのワークグループ。`nrc_train` は個数を 64 の倍数に切り上げ、`nrc_adam` は `PARAMS` 本、`nrc_infer` は問い合わせ数
- バッファの番号（Slang が決める）: `nrc_train` は P=0、G=1、cfg=4、samples=5。`nrc_adam` は P=0、G=1、M=2、V=3、cfg=4。`nrc_infer` は P=0、cfg=1、queries=2、out=3（宣言された順に詰まる）。`crates/verion-gpu-vulkan/src/reflect.rs` で SPIR-V の宣言を読めば確かめられる。Metal 側で同じ取り違えをして `infer` が 0 を返していた（`d79b82a` で修正）ので、まず小さく 1 本ずつ確かめる
- 1 サンプルは 12 語（位置 3、法線 3、目標色 3、語 9 = 1.0 が有効、残り 2 は 0）。語 9 が 0 のサンプルは `nrc_train` が読み飛ばすので、立てないと何も学習しない
- 時間は、コマンドバッファの前後のタイムスタンプ（`vkCmdWriteTimestamp`）で測る。ホストの時計は使わない

## 合格の確認（実験が正しいこと）
Metal の値と同じ性質が出ること。300 ステップ、バッチ 16384 で、相対誤差（`nrc_spike.rs` の relMSE）が 50 ステップで約 0.05、300 ステップで約 0.003。6 件の問い合わせの出力が目標に近い（誤差は数%）。これが出ないなら、速度の比較に意味がないので、バインディングか初期化を直す。

## 比べるもの
Mac（M4 Pro、AC 電源、2026-11-07）の値:

| 項目 | Metal |
|---|---|
| 学習 1 ステップ（バッチ 16384、`nrc_train` + `nrc_adam`）の中央値 | 0.68 ms |
| 推論 196608 件（512×384）の中央値 | 0.66 ms |
| ネットワークと勾配と Adam の状態 | 8.4 MB |
| 物理 PT の indoor（512×384、128 spp）の `gpu_s` | 0.724 s |
| NRC ありの indoor（同条件、検証つき）の `gpu_s` | 0.840 s |

RTX 3080 で次を測る: 学習 1 ステップ、推論 196608 件、`render-cli scenes/indoor.gltf --width 512 --height 384 --spp 128 --metrics m.json` の `gpu_s`（物理 PT。`--mode reference`）。

## 判断の基準
NRC の費用は、学習と推論のカーネルと、経路追跡の中の問い合わせ。経路追跡も 3080 では速くなるので、絶対値でなく比で見る。

- カーネルの速度比 = Metal の（学習ステップ + 推論）÷ 3080 の同じ値
- 経路追跡の速度比 = Metal の物理 PT の `gpu_s`（0.724 s）÷ 3080 の `gpu_s`
- カーネルの速度比が経路追跡の速度比より明らかに大きい（目安は 1.5 倍以上）なら、NRC の費用の割合が Vulkan では下がる。ホスト側（パイプライン 4 本、Buffer、`set_nrc`、検証のディスパッチ）を足す価値があるので、`nrc_collect`・`nrc_validate` も含めて移植を計画する。M7 の評価（ADR-0022）の同画質到達時間は、費用の割合から再計算できる
- 同程度か小さいなら、移植しても Metal と同じく ReSTIR GI に勝てない。ADR-0022 に結果を足して閉じる
- カーネルが想定より遅く、学習が律速と分かったら、Tensor コア（fp16 の融合 MLP）の案を ADR にまとめる。Vulkan の cooperative matrix / vector 拡張が RTX 3080 のドライバーで使えるかを調べる（私は確認していない）。Slang で一度書く方針から外れるので、採るかは利用者に確認する

## 書き戻すもの
- 測定値と判断を ADR-0022 の末尾に足す（日本語）。判断が「移植する」なら、M7 の項目 9 のような項目を M8 の表に足す前に、利用者に確認する（計画の更新）
- 実験の example は、判断が「閉じる」でも残してよい（Metal の `nrc_spike` と対）
