[Squeeth contracts](https://github.com/opynfinance/squeeth-monorepo/tree/main/packages/hardhat/contracts), ported to Forge.

Everything in `test` is actually designed to be used with their Hardhat tests, so it is sort of accidental that any of it runs with `forge test`.

Several things in [v3-core do not have proper pragma](https://github.com/Uniswap/v3-core/pull/525), and so you need to make sure you compile with 0.7.6. You can do this by 

1. Install https://github.com/roynalnaruto/svm-rs
2. `svm use 0.7.6`
3. ensure `which solc` shows something in `.cargo/bin` or else `export SOLC_PATH="/Users/<user name>/.cargo/bin/solc"`
4. run build and test commands with `--no-auto-detect`

Need to have the right number of optimizer runs for correct compilation, so run `build` and `test` commands with ` --optimize --optimize-runs 825`.

Example build `forge build --optimize --optimize-runs 825 --force --no-auto-detect`
Example test `forge test --optimize --optimize-runs 825 --force --no-auto-detect`