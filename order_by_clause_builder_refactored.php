<?php

function generate($hash, $included_columns)
{
    $query_string = "";
    $hashes       = [];

    if (!empty($hash))
    {
        foreach ($hash as $column => $direction)
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
                    $hashes[] = "{$included_columns[$direction]} $colDir";
                }
            }
            else
            {
                throw new \Exception("Invalid criteria: $column $direction");
            }
        }
        if(!empty($hashes))
        {
            $query_string = " ORDER BY " . join(", ", $hashes);
        }
    }
    return $query_string;
}