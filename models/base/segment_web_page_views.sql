with source as (

   		--the select * statement is the original
			--select * from {{var('segment_page_views_table')}} 
		    SELECT  
		        id
		        , anonymous_id
		        , user_id
		        , received_at
		        , sent_at
		        , received_at as timestamp
		        --, original_timestamp as timestamp
		        , context_page_url as url
		        , context_page_path as path
		        , context_page_title as title
		        , context_page_search as search
		        , context_page_referrer as referrer
		        , context_campaign_source
		        , context_campaign_medium
		        , context_campaign_name
		        , context_campaign_term
		        , context_campaign_content
		        , context_ip
		        , context_user_agent
		        , domain
		        , vertical
    FROM {{var('segment_page_views_table')}}

),

renamed as (

    select

        id as page_view_id,
        anonymous_id,
        user_id,

        received_at as received_at_tstamp,
        sent_at as sent_at_tstamp,
        timestamp as tstamp,

        url as page_url,
        {{ dbt_utils.get_url_host('url') }} as page_url_host,
        path as page_url_path,
        title as page_title,
        search as page_url_query,

        referrer,
        replace(
            {{ dbt_utils.get_url_host('referrer') }},
            'www.',
            ''
        ) as referrer_host,

        context_campaign_source as utm_source,
        context_campaign_medium as utm_medium,
        context_campaign_name as utm_campaign,
        context_campaign_term as utm_term,
        context_campaign_content as utm_content,
        {{ dbt_utils.get_url_parameter('url', 'gclid') }} as gclid,
        context_ip as ip,
        context_user_agent as user_agent,
        case
            when lower(context_user_agent) like '%android%' then 'Android'
            else replace(
                {{ dbt_utils.split_part(dbt_utils.split_part('context_user_agent', "'('", 2), "' '", 1) }},
                ';', '')
        end as device

        {% if var('segment_pass_through_columns') != [] %}
        ,
        {{ var('segment_pass_through_columns') | join (", ")}}

        {% endif %}

    from source

),

final as (

    select
        *,
        case
            when device = 'iPhone' then 'iPhone'
            when device = 'Android' then 'Android'
            when device in ('iPad', 'iPod') then 'Tablet'
            when device in ('Windows', 'Macintosh', 'X11') then 'Desktop'
            else 'Uncategorized'
        end as device_category
    from renamed

)

select * from final
