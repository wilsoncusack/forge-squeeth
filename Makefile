build :; forge build --optimize --optimize-runs 825 --force --no-auto-detect 
test :; forge test --optimize --optimize-runs 825 --force --no-auto-detect -f rpc
test-forking :; forge test --optimize --optimize-runs 825 --force --no-auto-detect -f rpc
test-forking-verbose :; forge test --optimize --optimize-runs 825 --force --no-auto-detect -f rpc -vv
