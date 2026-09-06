/*
    MACRO: cents_to_dollars
    
    Purpose: Convert cents to dollars with consistent formatting.
    Reusable across all models — shows you write DRY code.
    
    Usage in a model:
        {{ cents_to_dollars('amount_cents') }}
    
    Generates:
        (amount_cents / 100)::decimal(10,2)
*/

{% macro cents_to_dollars(column_name) -%}
    ({{ column_name }} / 100)::decimal(10,2)
{%- endmacro %}


/*
    MACRO: safe_divide
    
    Purpose: Divide two numbers safely without division-by-zero errors.
    Returns 0 when denominator is 0 or null.
    
    Usage:
        {{ safe_divide('revenue', 'orders') }}
    
    Generates:
        case when orders > 0 then revenue / orders else 0 end
*/

{% macro safe_divide(numerator, denominator, decimal_places=2) -%}
    case 
        when {{ denominator }} is not null and {{ denominator }} > 0 
        then round({{ numerator }}::decimal(18,6) / {{ denominator }}::decimal(18,6), {{ decimal_places }})
        else 0 
    end
{%- endmacro %}
