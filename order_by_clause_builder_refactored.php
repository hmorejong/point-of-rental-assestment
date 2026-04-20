<?php

function generate($hash, $included_columns)
{
    $query_string = "";
    $hashes       = [];

    if (!empty($hash))
    {
        foreach ($hash as $column => $direction)
        {
            if (in_array($direction, ['ASC', 'DESC']))
            {
                foreach($included_columns as $columnName => $columnValue)
                {
                    if ($column == $columnName)
                    {
                        $hashes[] = "$columnValue $direction ";
                    }
                }
            }
            elseif (is_int($column))
            {
                $colDir = "ASC";
                if (substr($direction, 0, 1) == "-")
                {
                    $direction = substr($direction, 1);
                    $colDir = "DESC";
                }
                if (array_key_exists($direction, $included_columns))
                {
                    $hashes[] = "{$included_columns[$direction]} $colDir ";
                }
            }
            else
            {
                throw new \Exception("Invalid criteria: $column $direction");
            }
        }
        if(!empty($hashes))
        {
            $query_string = " ORDER " . join(",", $hashes);
        }
    }
    return $query_string;
}