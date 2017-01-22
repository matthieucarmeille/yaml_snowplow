- explore: funnel_explorer
  always_filter:
    event_time: '30 days'
    
- view: funnel_explorer
      # In this query, we retrieve, for each session, the first and last instance of each event in our sequence. If, 
      # for each event, its first instance occurs before the last instance of the next event in the sequence, then     
      # that is considered a completion of the sequence.
- derived_table:
    sql: |
      SELECT sessions.unique_session_id as unique_session_id
        , events.user_id
        , sessions.session_start AS session_start
        , MIN(
            CASE WHEN
              {% condition event_1 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_1
        , MIN(
            CASE WHEN
              {% condition event_2 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_2_first
        , MAX(
            CASE WHEN
              {% condition event_2 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_2_last
        , MIN(
            CASE WHEN
              {% condition event_3 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_3_first
        , MAX(
            CASE WHEN
              {% condition event_3 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_3_last
        , MIN(
            CASE WHEN
              {% condition event_4 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_4_first
          , MAX(
            CASE WHEN
              {% condition event_4 %} events.page_path {% endcondition %} 
              THEN events.created_at
              ELSE NULL END
            ) AS event_4_last
      FROM ${events.SQL_TABLE_NAME} AS events
      LEFT JOIN ${sessions.SQL_TABLE_NAME} AS sessions 
        ON events.unique_session_id = sessions.unique_session_id
      WHERE {% condition event_time %} created_at {% endcondition %}
      GROUP BY 1,2,3

  fields:
  - filter: event_1
    suggest_dimension: events.page_path
    suggest_explore: events

  - filter: event_2
    suggest_dimension: events.page_path
    suggest_explore: events

  - filter: event_3
    suggest_dimension: events.page_path
    suggest_explore: events

  - filter: event_4
    suggest_dimension: events.page_path
    suggest_explore: events

  - filter: event_time
    type: datetime
  
  - dimension: unique_session_id
    type: string
    primary_key: TRUE
#     hidden: TRUE
    sql: ${TABLE}.unique_session_id

  - dimension: user_id
    type: number
#     hidden: TRUE
    sql: ${TABLE}.user_id
  
  - dimension_group: session_start
    type: time
#     hidden: TRUE
    timeframes: [time, date, week, month, year, raw]
    sql: ${TABLE}.session_start

  - dimension_group: event_1
    description: "First occurrence of event 1"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_1

  - dimension: event_2_first
    description: "First occurrence of event 2"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_2_first
  
  - dimension: event_2_last
    description: "Last occurrence of event 2"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_2_last

  - dimension: event_3_first
    description: "First occurrence of event 3"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_3_first

  - dimension: event_3_last
    description: "Last occurrence of event 3"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_3_last

  - dimension: event_4_first
    description: "First occurrence of event 4"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_4_first
  
  - dimension: event_4_last
    description: "Last occurrence of event 4"
    type: time
    timeframes: [time]
    hidden: true
    sql: ${TABLE}.event_4_last
  
  - dimension: event1_before_event2
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_1 < ${TABLE}.event_2_last

  - dimension: event1_before_event3
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_1 < ${TABLE}.event_3_last
  
  - dimension: event1_before_event4
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_1 < ${TABLE}.event_4_last

  - dimension: event2_before_event3
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_2_first < ${TABLE}.event_3_last
  
  - dimension: event2_before_event4
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_2_first < ${TABLE}.event_4_last

  - dimension: event3_before_event4
    type: yesno
    hidden: TRUE
    sql: ${TABLE}.event_3_first < ${TABLE}.event_4_last

  - dimension: reached_event_1
    hidden: true
    type: yesno
    sql: |
      (${event_1_time} IS NOT NULL)
  
  - dimension: reached_event_2
    hidden: true
    type: yesno
    sql: |
      (${event_1_time} IS NOT NULL AND ${event_2_first_time} IS NOT NULL AND ${event_1_time} < ${event_2_last_time})

  - dimension: reached_event_3
    hidden: true
    type: yesno
    sql: |
      (${event_1_time} IS NOT NULL AND ${event_2_last_time} IS NOT NULL AND ${event_3_last_time}  IS NOT NULL 
      AND ${event_1_time} < ${event_2_last_time} AND ${event_1_time} < ${event_3_last_time} AND ${event_2_first_time} < ${event_3_last_time})  
  
  - dimension: reached_event_4
    hidden: true
    type: yesno
    sql: |
     (${event_1_time} IS NOT NULL AND ${event_2_last_time} IS NOT NULL AND ${event_3_last_time}  IS NOT NULL AND ${event_4_last_time} IS NOT NULL
           AND ${event_1_time} < ${event_2_last_time} AND ${event_1_time} < ${event_3_last_time} AND ${event_1_time} < ${event_4_last_time} AND ${event_2_first_time} < ${event_3_last_time} AND ${event_2_first_time} < ${event_4_last_time} AND ${event_3_first_time} < ${event_4_last_time}) 

           
  - dimension: furthest_step
    label: "Furthest Funnel Step Reached"
    sql_case:
       4th: ${reached_event_4} = true
       3rd: ${reached_event_3} = true
       2nd: ${reached_event_2} = true
       1st: ${reached_event_1} = true
       else: no
  
  - measure: count_sessions
    type: count_distinct
    drill_fields: detail*
    sql: ${unique_session_id}
  
  - measure: count_sessions_event1
    label: 'Event 1'
    type: count_distinct
    sql: ${unique_session_id}
    drill_fields: detail*
    filters: 
      furthest_step: 1st, 2nd, 3rd, 4th
  
  - measure: count_sessions_event12
    label: 'Event 2'
    description: 'Only includes sessions which also completed event 1'
    type: count_distinct
    sql: ${unique_session_id}
    drill_fields: detail*
    filters: 
      furthest_step: 2nd, 3rd, 4th
  
  - measure: count_sessions_event123  
    label: 'Event 3'
    description: 'Only includes sessions which also completed events 1 and 2'
    type: count_distinct
    sql: ${unique_session_id}
    drill_fields: detail*
    filters: 
      furthest_step: 3rd, 4th
  
  - measure: count_sessions_event1234
    label: 'Event 4'
    description: 'Only includes sessions which also completed events 1, 2 and 3'
    type: count_distinct
    sql: ${unique_session_id}
    drill_fields: detail*
    filters: 
      furthest_step: 4th

       
  sets:
    detail:
      - unique_session_id
      - user_id
      - session_start_time