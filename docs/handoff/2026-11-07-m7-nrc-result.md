# 引き継ぎ: M7 の NRC を Metal で評価した結果

`2026-11-07-m7-start.md` の後継。状態の正本は `docs/implementation/M7-nrc-adaptive-integrator/README.md` の表。結果の詳細は ADR-0021（基準）と ADR-0022（結果）。

## 済んだこと（main に 7 コミット、push していない）
- 項目 1〜4・6・7: 評価の土台（`scripts/eval_nrc.sh`、16 seed と信頼区間、`--seed`）、評価シーン `indoor` と `cornell_diffuse`、NRC 本体（`--mode interactive --nrc`、Metal の Megakernel と Wavefront で一致）、編集後は捨てて学習し直す（`tests/update.rs`）
- 項目 8: 同画質到達時間（物理 PT 128 spp と同じ誤差まで、学習込み）。NRC（信頼しきい値 0.5）は indoor 1.55 倍、cornell_diffuse 1.23 倍、cornell_box 1.02 倍、many_lights は未達。ReSTIR GI は 1.66 / 1.78 / 2.26 / 3.87 倍で、4 シーンとも ReSTIR GI が速い。ウォームアップは約 150 ms、学習は 4 spp フレームあたり約 5 ms
- 項目 5: タイルごとの信頼度検証（`nrc_validate`、`--nrc-trust`）まで実装済み
- 既定は無効のまま、Reference モードは拒否。`mise run check`、`shaders:check`、Metal の GPU テストは通っている

## Windows でやること
- `PARAM_WORDS` が 81、パラメータ語 43 が seed、44〜48 が NRC、49〜80 がタイルのフォールバックビット。SPIR-V は再生成済み（`mise run shaders`）。`mise run check` と `mise run test:gpu` を回す。NRC のバインディングは `restir`（19）を共用していて、Vulkan のレイアウトは変えていない。Vulkan の `set_nrc(Some)` はエラーを返す（未実装）
- A5 の Vulkan の画像一致（`2026-11-07-alpha-cutout-windows.md`）は未了のまま

## 利用者の確認が要ること
1. （決定済み: 続けない）続けるかの基準の数値。仮に 2 倍以上と置くと 4 シーンとも通らない。通らないなら 9 以降（Vulkan、ReSTIR PT の判断、Adaptive Integrator、UI のスイッチ）は行わない、と README の項目 8 にある
2. 項目 10（REQ-ACC-002 の書き換え）、11・12（Adaptive Integrator を M7 に含めるか）、13（M1/M2 チップの扱い）
3. AGENTS.md の約束どおり、要件・仕様・計画への反映を聞く: NRC は一部のシーンでだけ効くので、REQ-ACC-004 を「選択式の機能。既定は無効」と明記してよいか
4. （決定済み、確認は不要）Metal のテクスチャなしシーンで約 2% 遅くなった件（アルファ対応）は許容する。原因は主経路と影レイでの不透明度の材質読み込み。特殊化定数で消すとパイプラインが Metal と Vulkan の両方で倍になり、得は約 2%（ベンチの許容 10% の内側）なので保守費用に合わない。Windows で Vulkan が大きく退行（5% 超）していたときだけ見直す
