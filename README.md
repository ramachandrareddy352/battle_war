## About

   **This project is meant to be a Battle War. Where every wallet address can maintain a single army only. Every army have defenders, attackers, machines, raiders and health. Every day you can get daily rewards and using this rewards you can build your army.**
    **You can attack other army for single time in a day. For every winning or losing battle the win count and lose count is tracked, for winning you can get the rewards and for every 5 wins you can get a NFT token. For attacking in battle you army also lost based on opponent army.**
    **If you are buying army in bulk can reduce the amount and you can also buy army by paying ethers also.Your battle data are tracked in every attacks.**

## Documentation

https://book.getfoundry.sh/

### Quickstart

```
git clone https://github.com/ramachandrareddy352/battle_war
cd battle_war
forge build
```

### Updates
- The latest version of openzeppelin-contracts has changes in the ERC20Mock file. To follow along with the course, you need to install version 4.8.3 which can be done by ```forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit``` instead of ```forge install openzeppelin/openzeppelin-contracts --no-commit```

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`


### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```
