/**
 * Standalone Node test runner for listener_collection_refactored.js
 *
 * Loads the implementation after stubbing global `angular`
 * (matches AngularJS-era dependency without a browser).
 *
 * Run: node listener_collection_refactored_test.js
 */

'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

global.angular = {
    isFunction: function (fn) {
        return typeof fn === 'function';
    },
    noop: function () {}
};

const sourcePath = path.join(__dirname, 'listener_collection_refactored.js');
vm.runInThisContext(fs.readFileSync(sourcePath, 'utf8'), { filename: sourcePath });

function printTestSeparator() {
    console.log('-'.repeat(40) + '\n');
}

function printTestBlock(num, desc, expected, actual, passed) {
    var statusIcon = passed ? '✅' : '❌';
    var statusText = passed ? 'OK' : 'FAILURE';
    console.log('Test ' + num + ': ' + desc + '\n');
    console.log('Expected: ' + expected);
    console.log('Actual:   ' + actual);
    console.log('Result:   ' + (passed ? 'PASS' : 'FAIL') + '\n');
    console.log('Status:   ' + statusIcon + ' ' + statusText + '\n');
}

var tests = [
    {
        num: 1,
        desc: 'addListener registers a new callback and trigger invokes it',
        expected: 'listeners.length === 1 after add; calls === 1 after trigger()',
        run: function () {
            var col = new ListenerCollection([]);
            var calls = 0;
            col.addListener(function () {
                calls++;
            });
            assert.strictEqual(col.listeners.length, 1);
            return col.trigger().then(function () {
                assert.strictEqual(calls, 1);
                return 'listeners.length=1; calls=1 after trigger()';
            });
        }
    },
    {
        num: 2,
        desc: 'addListener does not register the same function twice',
        expected: 'listeners.length === 1 after two addListener(fn) calls',
        run: function () {
            var col = new ListenerCollection([]);
            var fn = function () {};
            col.addListener(fn);
            col.addListener(fn);
            assert.strictEqual(col.listeners.length, 1);
            return 'listeners.length=1';
        }
    },
    {
        num: 3,
        desc: 'removeListener removes the first listener (index 0)',
        expected: 'after removeListener(first), only second callback remains',
        run: function () {
            var col = new ListenerCollection([]);
            var a = function () {};
            var b = function () {};
            col.addListener(a);
            col.addListener(b);
            assert.strictEqual(col.listeners.length, 2);
            col.removeListener(a);
            assert.strictEqual(col.listeners.length, 1);
            assert.strictEqual(col.listeners[0], b);
            return 'listeners.length=1; remaining listener is second';
        }
    },
    {
        num: 4,
        desc: 'teardown returned from addListener removes the listener',
        expected: 'listeners.length === 0 after calling returned unsubscribe function',
        run: function () {
            var col = new ListenerCollection([]);
            var fn = function () {};
            var off = col.addListener(fn);
            assert.strictEqual(col.listeners.length, 1);
            off();
            assert.strictEqual(col.listeners.length, 0);
            return 'listeners.length=0';
        }
    },
    {
        num: 5,
        desc: 'removeAllListeners clears the collection',
        expected: 'listeners.length === 0; hasListeners() === false',
        run: function () {
            var col = new ListenerCollection([]);
            col.addListener(function () {});
            col.addListener(function () {});
            col.removeAllListeners();
            assert.strictEqual(col.listeners.length, 0);
            assert.strictEqual(col.hasListeners(), false);
            return 'listeners.length=0; hasListeners=false';
        }
    },
    {
        num: 6,
        desc: 'non-function listener returns a function and does not add',
        expected: 'typeof return === "function"; listeners.length === 0',
        run: function () {
            var col = new ListenerCollection([]);
            var ret = col.addListener({});
            assert.strictEqual(typeof ret, 'function');
            assert.strictEqual(col.listeners.length, 0);
            return 'typeof teardown=function; listeners.length=0';
        }
    },
    {
        num: 7,
        desc: 'trigger forwards arguments to listeners',
        expected: 'listener receives (2, 3) and observed sum === 5',
        run: function () {
            var col = new ListenerCollection([]);
            var seen = null;
            col.addListener(function (x, y) {
                seen = x + y;
            });
            return col.trigger(2, 3).then(function () {
                assert.strictEqual(seen, 5);
                return 'seen=5 after trigger(2, 3)';
            });
        }
    }
];

var total = tests.length;
var passedCount = 0;
var failedCount = 0;
var testResults = {};

function runNext(index) {
    if (index >= tests.length) {
        return Promise.resolve();
    }
    var t = tests[index];
    return Promise.resolve()
        .then(function () {
            return t.run();
        })
        .then(function (actual) {
            passedCount++;
            testResults[t.num] = true;
            printTestBlock(t.num, t.desc, t.expected, actual, true);
        })
        .catch(function (e) {
            failedCount++;
            testResults[t.num] = false;
            var msg = e && e.message ? e.message : String(e);
            printTestBlock(t.num, t.desc, t.expected, msg, false);
        })
        .then(function () {
            if (index < tests.length - 1) {
                printTestSeparator();
            }
            return runNext(index + 1);
        });
}

console.log('========================================');
console.log('TESTS START');
console.log('========================================\n');

runNext(0)
    .then(function () {
        var unexpected = 0;
        for (var n = 1; n <= total; n++) {
            if (testResults[n] !== true) {
                unexpected++;
            }
        }

        console.log('========================================');
        console.log('TESTS RESULTS');
        console.log('========================================\n');

        if (unexpected === 0) {
            console.log('✅ EXPECTED OUTCOMES VERIFIED\n');
        } else {
            console.log('❌ UNEXPECTED TEST OUTCOMES (' + unexpected + ')\n');
        }

        console.log('Tests: ' + total + ', Passed: ' + passedCount + ', Failed: ' + failedCount);
        console.log('Assertions: ' + total);
        console.log('========================================');

        process.exit(unexpected === 0 ? 0 : 1);
    })
    .catch(function (e) {
        console.error(e);
        process.exit(1);
    });
