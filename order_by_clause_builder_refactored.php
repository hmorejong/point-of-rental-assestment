<?php

/**
 * Builds an SQL ORDER BY clause from the given sort criteria.
 *
 * Supports both associative input (e.g. ['Method' => 'DESC']) and
 * indexed shorthand syntax (e.g. ['-FieldValue', 'CreatedDate']).
 *
 * Column names are validated against the provided whitelist to prevent
 * invalid or unsafe fields from being included in the query.
 *
 * @param array $sort_criteria     Sort definition (column => direction or shorthand values)
 * @param array $included_columns Whitelist mapping of allowed fields to SQL column expressions
 *
 * @return string A formatted ORDER BY clause, or an empty string if no valid criteria is provided
 *
 * @throws \InvalidArgumentException If invalid sort criteria is encountered
 */
function generate(array $sort_criteria, array $included_columns): string
{
    $query_string = '';
    $hashes       = [];

    if (!empty($sort_criteria))
    {
        foreach ($sort_criteria as $column => $direction)
        {
            $direction = strtoupper($direction);

            if (in_array($direction, ['ASC', 'DESC'], true))
            {
                if (array_key_exists($column, $included_columns))
                {
                    $hashes[] = "{$included_columns[$column]} $direction";
                }
            }
            else if (is_int($column))
            {
                $colDir    = str_starts_with($direction, '-') ? 'DESC' : 'ASC';
                $columnKey = ltrim($direction, '-');

                if (array_key_exists($columnKey, $included_columns))
                {
                    $hashes[] = "{$included_columns[$columnKey]} $colDir";
                }
            }
            else
            {
                throw new \InvalidArgumentException("Invalid criteria: $column $direction");
            }
        }
        
        if (!empty($hashes))
        {
            $query_string = " ORDER BY " . join(", ", $hashes);
        }
    }

    return $query_string;
}