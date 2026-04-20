<?php

declare(strict_types = 1);

require_once __DIR__ . '/order_by_clause_builder_refactored.php';

$included_columns = [
    'CreatedDate' => 'CreatedDate',
    'Method'      => 'OrderType.Method',
    'TableId'     => 'TableId',
    'FieldValue'  => 'JoinedTable.FieldValue'
];

function print_test_result(int $test_number, string $description, string $actual, string $expected): bool
{
    $passed     = ($actual === $expected);
    $statusIcon = $passed ? '✅' : '❌';
    $statusText = $passed ? 'OK' : 'FAILURE';

    echo "Test {$test_number}: {$description}\n" . PHP_EOL;
    echo "Expected: {$expected}\n";
    echo "Actual:   {$actual}\n";
    echo "Result:   " . ($passed ? 'PASS' : 'FAIL') . "\n\n";
    echo "Status:   {$statusIcon} {$statusText}\n\n";

    return $passed;
}

function print_test_separator(): void
{
    echo str_repeat('-', 40) . "\n\n";
}

$passed = 0;
$failed = 0;
$total  = 6;
$testResults = [];

echo "========================================\n";
echo "TESTS START\n";
echo "========================================\n\n";

// Test 1: The exact call from the assessment - mixed array formats
$sort_criteria1 = ['CreatedDate', 'Method' => 'DESC', '-FieldValue'];
$expected1      = ' ORDER BY CreatedDate ASC, OrderType.Method DESC, JoinedTable.FieldValue DESC';
$actual1        = generate($sort_criteria1, $included_columns);
$testResults[1] = print_test_result(1, 'mixed array formats', $actual1, $expected1);
$testResults[1] ? $passed++ : $failed++;
print_test_separator();

// Test 2: All string-keyed with explicit directions
$sort_criteria2 = ['CreatedDate' => 'ASC', 'Method' => 'DESC', 'TableId' => 'ASC'];
$expected2      = ' ORDER BY CreatedDate ASC, OrderType.Method DESC, TableId ASC';
$actual2        = generate($sort_criteria2, $included_columns);
$testResults[2] = print_test_result(2, 'all string-keyed with explicit directions', $actual2, $expected2);
$testResults[2] ? $passed++ : $failed++;
print_test_separator();

// Test 3: All integer-indexed, mix of ASC and DESC
$sort_criteria3 = ['CreatedDate', '-Method', 'TableId', '-FieldValue'];
$expected3      = ' ORDER BY CreatedDate ASC, OrderType.Method DESC, TableId ASC, JoinedTable.FieldValue DESC';
$actual3        = generate($sort_criteria3, $included_columns);
$testResults[3] = print_test_result(3, 'integer-indexed shorthand criteria', $actual3, $expected3);
$testResults[3] ? $passed++ : $failed++;
print_test_separator();

// Test 4: Column not in whitelist - should be silently skipped
$sort_criteria4 = ['NonExistentColumn' => 'ASC', 'Method' => 'DESC'];
$expected4      = ' ORDER BY OrderType.Method DESC';
$actual4        = generate($sort_criteria4, $included_columns);
$testResults[4] = print_test_result(4, 'non-whitelisted column is skipped', $actual4, $expected4);
$testResults[4] ? $passed++ : $failed++;
print_test_separator();

// Test 5: Empty criteria - should return empty string
$sort_criteria5 = [];
$expected5      = '';
$actual5        = generate($sort_criteria5, $included_columns);
$testResults[5] = print_test_result(5, 'empty criteria returns empty string', $actual5, $expected5);
$testResults[5] ? $passed++ : $failed++;
print_test_separator();

// Test 6: Invalid criteria direction - should throw InvalidArgumentException
try
{
    $sort_criteria6 = ['Method' => 'INVALID_DIRECTION'];
    $actual6        = generate($sort_criteria6, $included_columns);
    $passedTest6    = false;

    echo "Test 6: invalid string-keyed direction throws exception\n";
    echo "Expected: Invalid criteria: Method INVALID_DIRECTION\n";
    echo "Actual:   {$actual6}\n";
    echo "Result:   FAIL (no exception)\n\n";
    echo "Status:   ❌ FAILURE\n\n";

    $testResults[6] = false;
    $failed++;
}
catch (\InvalidArgumentException $e)
{
    $passedTest6 = ($e->getMessage() === 'Invalid criteria: Method INVALID_DIRECTION');
    $statusIcon  = $passedTest6 ? '✅' : '❌';
    $statusText  = $passedTest6 ? 'OK' : 'FAILURE';

    echo "Test 6: invalid string-keyed direction throws exception\n";
    echo "Expected: Invalid criteria: Method INVALID_DIRECTION\n";
    echo "Actual:   {$e->getMessage()}\n";
    echo "Result:   " . ($passedTest6 ? 'PASS' : 'FAIL') . "\n\n";
    echo "Status:   {$statusIcon} {$statusText}\n\n";

    $testResults[6] = $passedTest6;
    $passedTest6 ? $passed++ : $failed++;
}
catch (\Throwable $e)
{
    echo "Test 6: invalid string-keyed direction throws exception\n";
    echo "Expected: Invalid criteria: Method INVALID_DIRECTION\n";
    echo "Actual:   " . get_class($e) . ' - ' . $e->getMessage() . "\n";
    echo "Result:   FAIL (unexpected exception type)\n\n";
    echo "Status:   ❌ FAILURE\n\n";

    $testResults[6] = false;
    $failed++;
}

$expectedResults = [
    1 => false,
    2 => true,
    3 => false,
    4 => true,
    5 => true,
    6 => true
];

$unexpectedOutcomes = 0;
foreach ($expectedResults as $testNumber => $expectedPass)
{
    if (!array_key_exists($testNumber, $testResults) || $testResults[$testNumber] !== $expectedPass)
    {
        $unexpectedOutcomes++;
    }
}

echo "========================================\n";
echo "TESTS RESULTS\n";
echo "========================================\n";

if ($unexpectedOutcomes === 0)
{
    echo "✅ EXPECTED OUTCOMES VERIFIED\n";
}
else
{
    echo "❌ UNEXPECTED TEST OUTCOMES ({$unexpectedOutcomes})\n";
}

echo "Tests: {$total}, Passed: {$passed}, Failed: {$failed}\n";
echo "Assertions: {$total}\n";
echo "========================================\n";

exit($unexpectedOutcomes === 0 ? 0 : 1);