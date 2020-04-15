const { time } = require('openzeppelin-test-helpers');

const LockDropContract = artifacts.require("LockDrop");
const COLTokenContract = artifacts.require("COLToken");

contract('COLToken with LockDrop', async(accounts) => {
    let actors = {
        tokenOwner: accounts[0],
        locker1: accounts[1],
        locker2: accounts[2],
        locker3: accounts[3],
        locker4: accounts[4],
        locker5: accounts[5],
        malicious: accounts[6]
    };

    let lockdropInst;
    let tokenInst;
    let lockDeadline;
    let dropStartTimeStamp;
    const totalAmountOfTokenDrop = 20000000000;

    const zeroAddress = "0x0000000000000000000000000000000000000000";

    let expectThrow = async (promise) => {
        try {
            await promise;
        } catch (error) {
            const invalidOpcode = error.message.search('invalid opcode') >= 0;
            const outOfGas = error.message.search('out of gas') >= 0;
            const revert = error.message.search('revert') >= 0;
            assert(
                invalidOpcode || outOfGas || revert,
                "Expected throw, got '" + error + "' instead",
            );
          return;
        }
        assert.fail('Expected throw not received');
    };

    let takeSnapshot = () => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_snapshot',
            id: new Date().getTime()
          }, (err, snapshotId) => {
            if (err) { return reject(err) }
            return resolve(snapshotId)
          })
        })
    };

    let revertToSnapShot = (id) => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_revert',
            params: [id],
            id: new Date().getTime()
          }, (err, result) => {
            if (err) { return reject(err) }
            return resolve(result)
          })
        })
    };

    before("preparing env", async() => {
        tokenInst = await COLTokenContract.new({from: actors.tokenOwner});
        lockdropInst = await LockDropContract.new(tokenInst.address, {from: actors.tokenOwner});

        // settting lock drop address in token contract

        //wrong access
        await expectThrow(
            tokenInst.setLDContract(lockdropInst.address, {from: actors.malicious})
        );

        // wrong address value
        await expectThrow(
            tokenInst.setLDContract(zeroAddress, {from: actors.tokenOwner})
        );

        await tokenInst.setLDContract(lockdropInst.address, {from: actors.tokenOwner});

        console.log("[DEBUG] Token address", tokenInst.address);
        console.log("[DEBUG] LockDrop address", lockdropInst.address);
    })

    it("shouldn't lock funds", async() => {
        // deadline is out
        let currentSnapshot = await takeSnapshot();
        let snapshotId = currentSnapshot['result']

        await time.advanceBlock();
        let start = await time.latest();
        lockDeadline = start.add(time.duration.hours(24));
        await time.increaseTo(lockDeadline);

        await expectThrow(
            lockdropInst.lock({from: actors.locker1, value: web3.utils.toWei("1", "ether")})
        );
        await revertToSnapShot(snapshotId);

        // wrong value
        await expectThrow(
            lockdropInst.lock({from: actors.locker1, value: 0})
        );
    });

    it("should lock funds from 5 users", async() => {
        await lockdropInst.lock({from: actors.locker1, value: web3.utils.toWei("1", "ether")});
        await lockdropInst.lock({from: actors.locker1, value: web3.utils.toWei("1", "ether")});
        
        let locker1LockBalance = await lockdropInst.lockedAmounts.call(actors.locker1);
        assert.equal(locker1LockBalance, web3.utils.toWei("2", "ether"));

        await lockdropInst.lock({from: actors.locker2, value: web3.utils.toWei("2", "ether")});
        await lockdropInst.lock({from: actors.locker3, value: web3.utils.toWei("2", "ether")});
        await lockdropInst.lock({from: actors.locker4, value: web3.utils.toWei("2", "ether")});
        await lockdropInst.lock({from: actors.locker5, value: web3.utils.toWei("2", "ether")});

        let lockDropBalance = await web3.eth.getBalance(lockdropInst.address);
        assert.equal(lockDropBalance, web3.utils.toWei("10", "ether"));
        
    });

    it("shouldn't claim tokens and ether, drop hasn't started yet", async() => {
        // lock time period ended up
        await time.increaseTo(lockDeadline);

        await expectThrow(
            lockdropInst.claim({from: actors.locker1})
        );
        await expectThrow(
            lockdropInst.lock({from: actors.locker1, value: web3.utils.toWei("1", "ether")})
        );
    });

    it("should claim tokens and ether back", async() => {
        let start = await time.latest();
        dropStartTimeStamp = start.add(time.duration.hours(168));
        await time.increaseTo(dropStartTimeStamp);

        await lockdropInst.claim({from: actors.locker1});
        // can't claim many times
        await expectThrow(
            lockdropInst.claim({from: actors.locker1})
        );
        await lockdropInst.claim({from: actors.locker2});
        await lockdropInst.claim({from: actors.locker3});
        await lockdropInst.claim({from: actors.locker4});
        await lockdropInst.claim({from: actors.locker5});

        let lockDropBalance = await web3.eth.getBalance(lockdropInst.address);
        assert.equal(lockDropBalance, 0);
    });

    it("check token balances", async() => {
        let balanceLocker1 = await tokenInst.balanceOf(actors.locker1);
        assert.equal(balanceLocker1, 1000000000);
        let balanceLocker2 = await tokenInst.balanceOf(actors.locker2);
        assert.equal(balanceLocker2, 1000000000);
        let balanceLocker3 = await tokenInst.balanceOf(actors.locker3);
        assert.equal(balanceLocker3, 1000000000);
        let balanceLocker4 = await tokenInst.balanceOf(actors.locker4);
        assert.equal(balanceLocker4, 1000000000);
        let balanceLocker5 = await tokenInst.balanceOf(actors.locker5);
        assert.equal(balanceLocker5, 1000000000);
    })
})