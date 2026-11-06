# 引き継ぎ: M7 の NRC を Metal で評価した結果

`2026-11-07-m7-start.md` の後継。状態の正本は `docs/implementation/M7-nrc-adaptive-integrator/README.md` の表。結果の詳細は ADR-0021（基準）と ADR-0022（結果）。

## 済んだこと（main に 7 コミット、push していない）
- 項目 1〜4・6・7: 評価の土台（`scripts/eval_nrc.sh`、16 seed と信頼区間、`--seed`）、評価シーン `indoor` と `cornell_diffuse`、NRC 本体（`--mode interactive --nrc`、Metal の Megakernel と Wavefront で一致）、編集後は捨てて学習し直す（`tests/update.rs`）
- 項目 8: 同画質到達時間（物理 PT 128 spp と同じ誤差まで、学習込み）。NRC は indoor 2.15 倍、cornell_diffuse 1.28 倍、cornell_box 1.08 倍、many_lights は未達。ReSTIR GI は 1.66 / 1.78 / 2.26 / 3.87 倍で、NRC が勝つのは indoor だけ
- 既定は無効のまま、Reference モードは拒否。`mise run check`、`shaders:check`、Metal の GPU テストは通っている

## Windows でやること
- `PARAM_WORDS` が 49、パラメータ語 43 が seed、44〜48 が NRC。SPIR-V は再生成済み（`mise run shaders`）。`mise run check` と `mise run test:gpu` を回す。NRC のバインディングは `restir`（19）を共用していて、Vulkan のレイアウトは変えていない。Vulkan の `set_nrc(Some)` はエラーを返す（未実装）
- A5 の Vulkan の画像一致（`2026-11-07-alpha-cutout-windows.md`）は未了のまま

## 利用者の確認が要ること
1. 続けるかの基準の数値。仮に 2 倍以上と置くと 4 シーン中 1 つだけ。通らないなら 9 以降（Vulkan、ReSTIR PT の判断、Adaptive Integrator、UI のスイッチ）は行わない、と README の項目 8 にある
2. 項目 10（REQ-ACC-002 の書き換え）、11・12（Adaptive Integrator を M7 に含めるか）、13（M1/M2 チップの扱い）
3. AGENTS.md の約束どおり、要件・仕様・計画への反映を聞く: NRC は一部のシーンでだけ効くので、REQ-ACC-004 を「選択式の機能。既定は無効」と明記してよいか
4. Metal のテクスチャなしシーンで約 2% 遅くなった件（アルファ対応）は未決のまま
