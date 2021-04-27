SET SERVEROUTPUT ON;

SET VERIFY OFF;

DECLARE
    /* DATA TYPES */
    SUBTYPE name_t IS VARCHAR2(35);
    SUBTYPE whole_num_t IS NUMBER(5, 0);
    SUBTYPE point_t IS PLS_INTEGER;
    SUBTYPE event_t IS points_system.event%TYPE;
    SUBTYPE result_t IS points_system.a%TYPE;
    SUBTYPE points_system_t IS points_system%rowtype;
    SUBTYPE text_t IS VARCHAR2(484);
    TYPE points_system_vt IS
        VARRAY(10) OF points_system_t;
    TYPE event_dictionary_at IS
        TABLE OF PLS_INTEGER INDEX BY event_t;
    TYPE event_order_vt IS
        VARRAY(10) OF event_t;
    TYPE event_results_vt IS
        VARRAY(10) OF result_t;
    TYPE athlete_results_rt IS RECORD (
        athlete  name_t,
        ev_res   event_results_vt
    );
    TYPE athletes_results_nt IS
        TABLE OF athlete_results_rt NOT NULL;
    TYPE athlete_points_rt IS RECORD (
        athlete  name_t,
        points   whole_num_t
    );
    TYPE decathlon_positions_nt IS
        TABLE OF athlete_points_rt;
    /* END OF DATA TYPES */
    
    /* VARIABLES */
    l_pnts_sys    points_system_vt;
    l_ev_dict     event_dictionary_at;
    l_ev_order    event_order_vt;
    l_athls_res   athletes_results_nt;
    l_dcthl_pos   decathlon_positions_nt;
    /* END OF VARIABLES */
    
    /* CONSTANTS */
    c_new_line    CONSTANT CHAR := chr(13);
    c_input_data  CONSTANT text_t := 'Atletë1 - 12.61;5.00;9.22;1.50;60.39;16.43;21.60;2.60;35.81;5.25.72'
                                    || c_new_line
                                    || 'Atletë2 - 13.04;4.53;7.79;1.55;64.72;18.74;24.20;2.40;28.20;6.50.76'
                                    || c_new_line
                                    || 'Atletë3 - 13.75;4.84;10.12;1.50;68.44;19.18;30.85;2.80;33.88;6.22.75'
                                    || c_new_line
                                    || 'Atletë4 - 13.04;4.53;7.79;1.55;64.72;18.74;24.20;2.40;28.20;6.50.76'
                                    || c_new_line
                                    || 'Atletë5 - 12.61;5.00;9.22;1.50;60.39;16.43;21.60;2.60;35.81;5.25.72'
                                    || c_new_line
                                    || 'Atletë6 - 12.61;5.00;9.22;1.50;60.39;16.43;21.60;2.60;35.81;5.25.72'
                                    || c_new_line
                                    || 'Atletë7 - 13.43;4.35;8.64;1.50;66.06;19.05;24.89;2.20;33.48;6.51.01'
                                    || c_new_line;
    /* END OF CONSTANTS */
    
    /* LOCAL MODULES */
    FUNCTION init_athlete_results (
        i_athlete  IN  name_t,
        i_ev_res   IN  event_results_vt
    ) RETURN athlete_results_rt IS
        l_athl_res athlete_results_rt;
    BEGIN
        l_athl_res.athlete := i_athlete;
        l_athl_res.ev_res := i_ev_res;
        RETURN l_athl_res;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during athlete's results record initialization!]');
    END init_athlete_results;

    FUNCTION init_athlete_points (
        i_athlete  IN  name_t,
        i_points   IN  point_t
    ) RETURN athlete_points_rt IS
        l_athl_pnts athlete_points_rt;
    BEGIN
        l_athl_pnts.athlete := i_athlete;
        l_athl_pnts.points := i_points;
        RETURN l_athl_pnts;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during athlete's points record initialization!]');
    END init_athlete_points;

    PROCEDURE init_points_system IS
    BEGIN
        SELECT
            event,
            a,
            b,
            c,
            unit
        BULK COLLECT
        INTO l_pnts_sys
        FROM
            points_system;

        << init_event_to_index_dict >> FOR ev_index IN l_pnts_sys.first..l_pnts_sys.last LOOP
            l_ev_dict(l_pnts_sys(ev_index).event) := ev_index;
        END LOOP init_event_to_index_dict;

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during points system's array initialization!]');
    END init_points_system;

    PROCEDURE bubble_sort (
        io_dcthl_pos IN OUT NOCOPY decathlon_positions_nt
    ) IS
        l_temp         athlete_points_rt;
        l_right_index  PLS_INTEGER;
        l_arr_index    PLS_INTEGER;
    BEGIN
        l_right_index := io_dcthl_pos.count;
        << outer_loop >> WHILE l_right_index >= 1 LOOP
            l_arr_index := 1;
            << inner_loop >> WHILE l_arr_index < l_right_index LOOP
                IF io_dcthl_pos(l_arr_index).points < io_dcthl_pos(l_arr_index + 1).points THEN
                    l_temp := io_dcthl_pos(l_arr_index);
                    io_dcthl_pos(l_arr_index) := io_dcthl_pos(l_arr_index + 1);
                    io_dcthl_pos(l_arr_index + 1) := l_temp;
                END IF;

                l_arr_index := l_arr_index + 1;
            END LOOP inner_loop;

            l_right_index := l_right_index - 1;
        END LOOP outer_loop;

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during bubble sorting decathlon positions!]');
    END bubble_sort;

    PROCEDURE print_decathlon_positions (
        i_dcthl_pos IN decathlon_positions_nt
    ) IS
        l_position CHAR(5);
    BEGIN
        l_position := 1;
        << pretty_printing >> FOR ath_index IN i_dcthl_pos.first..i_dcthl_pos.last LOOP
            CASE
                WHEN ath_index = i_dcthl_pos.first THEN
                    IF i_dcthl_pos(ath_index).points = i_dcthl_pos(ath_index + 1).points THEN
                        l_position := l_position + 0.1;
                    END IF;
                WHEN ath_index = i_dcthl_pos.last THEN
                    IF i_dcthl_pos(ath_index).points = i_dcthl_pos(ath_index - 1).points THEN
                        l_position := l_position + 0.1;
                    ELSE
                        l_position := trunc(l_position, 0) + 1;
                    END IF;
                ELSE
                    IF
                        i_dcthl_pos(ath_index).points != i_dcthl_pos(ath_index - 1).points
                        AND i_dcthl_pos(ath_index).points = i_dcthl_pos(ath_index + 1).points
                    THEN
                        l_position := trunc(l_position, 0) + 1.1;
                    ELSIF i_dcthl_pos(ath_index).points = i_dcthl_pos(ath_index - 1).points OR i_dcthl_pos(ath_index).points = i_dcthl_pos(
                    ath_index + 1).points THEN
                        l_position := l_position + 0.1;
                    ELSE
                        l_position := trunc(l_position, 0) + 1;
                    END IF;
            END CASE;

            dbms_output.put_line(replace(l_position, ',', '-')
                                 || ' '
                                 || i_dcthl_pos(ath_index).athlete
                                 || ' '
                                 || i_dcthl_pos(ath_index).points);

        END LOOP pretty_printing;

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during decathlon positions printing!]');
    END print_decathlon_positions;
    /* END OF LOCAL MODULES */

BEGIN
    init_points_system;
    l_ev_order := event_order_vt('100 m', 'Long jump', 'Shot put', 'High jump', '400 m',
                                '110 m hurdles',
                                'Discus throw',
                                'Pole vault',
                                'Javelin throw',
                                '1500 m');

    l_athls_res := athletes_results_nt();
    << parsing_input >> DECLARE
        l_text               text_t;
        l_results            text_t;
        l_name               name_t;
        c_result_delimiter   CONSTANT CHAR := ';';
        c_name_delimiter     CONSTANT CHAR(3) := ' - ';
        c_decimal_separator  CONSTANT CHAR(2) := '\.';
        c_number_pattern     CONSTANT CHAR(8) := '\d+\.\d+';
        c_number_mask        CONSTANT CHAR(5) := '99.99';
        l_ev_res             event_results_vt;
        l_count              PLS_INTEGER;

        FUNCTION start_pattern (
            i_string   IN  VARCHAR2,
            i_pattern  IN  CHAR,
            i_offset   IN  PLS_INTEGER := 0
        ) RETURN VARCHAR2 IS
        BEGIN
            RETURN substr(i_string, regexp_instr(i_string, i_pattern) + i_offset);
        END start_pattern;

        FUNCTION prior_pattern (
            i_string   IN  VARCHAR2,
            i_pattern  IN  CHAR
        ) RETURN VARCHAR2 IS
        BEGIN
            RETURN substr(i_string, 1, regexp_instr(i_string, i_pattern) - 1);
        END prior_pattern;

    BEGIN
        l_text := c_input_data;
        l_count := regexp_count(l_text, c_new_line);
        << foreach_athlete_results >> FOR ath_index IN 1..l_count LOOP
            l_results := prior_pattern(l_text, c_new_line);
            l_text := start_pattern(l_text, c_new_line, i_offset => 1);
            l_name := prior_pattern(l_results, c_name_delimiter);
            l_results := start_pattern(l_results, c_number_pattern);
            l_ev_res := event_results_vt();
            FOR res_index IN 1..9 LOOP
                l_ev_res.extend();
                l_ev_res(res_index) := to_number(prior_pattern(l_results, c_result_delimiter), c_number_mask);
                l_results := start_pattern(l_results, c_result_delimiter, 1);
            END LOOP;

            l_ev_res.extend();
            l_ev_res(10) := to_number(prior_pattern(l_results, c_decimal_separator)) * 60 + to_number(start_pattern(l_results, c_decimal_separator,
            1), c_number_mask);

            l_athls_res.extend();
            l_athls_res(ath_index) := init_athlete_results(i_athlete => l_name, i_ev_res => l_ev_res);

        END LOOP foreach_athlete_results;

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during athletes results' sequence parsing!]');
    END parsing_input;

    l_dcthl_pos := decathlon_positions_nt();
    << decathlon_results >> DECLARE
        l_ev_res  event_results_vt;
        l_points  point_t;
    BEGIN
        << foreach_athlete >> FOR ath_index IN l_athls_res.first..l_athls_res.last LOOP
            l_ev_res := l_athls_res(ath_index).ev_res;
            l_points := 0;
            << foreach_event >> FOR ev_index IN l_ev_res.first..l_ev_res.last LOOP
                << point_calculation >> DECLARE
                    l_ev_sys  points_system_t;
                    l_error   point_t;
                    l_point   point_t;
                BEGIN
                    l_ev_sys := l_pnts_sys(l_ev_dict(l_ev_order(ev_index)));
                    l_error := 1;
                    l_point := 0;
                    CASE l_ev_sys.unit
                        WHEN 'seconds' THEN
                            l_point := trunc(l_ev_sys.a * power(l_ev_sys.b - l_ev_res(ev_index), l_ev_sys.c), 0);
                        WHEN 'metres' THEN
                            IF l_ev_sys.event IN ( 'Long jump', 'High jump', 'Pole vault' ) THEN
                                l_error := 100;
                            END IF;

                            l_point := trunc(l_ev_sys.a * power(l_ev_res(ev_index) * l_error - l_ev_sys.b, l_ev_sys.c), 0);

                        ELSE
                            dbms_output.put_line('Error! No such decathlon event exists.');
                    END CASE;

                    --dbms_output.put_line(l_point);
                    l_points := l_points + l_point;
                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line(q'[Error during athlete's ' || l_athls_res(i).ev_name || ' point calculation.]');
                END point_calculation;
            END LOOP foreach_event;
            
            --dbms_output.put_line('ATHLETE: ' || l_athls_res(i).athlete || ' POINTS: ' || l_points);
            l_dcthl_pos.extend();
            l_dcthl_pos(ath_index) := init_athlete_points(i_athlete => l_athls_res(ath_index).athlete, i_points => l_points);

        END LOOP foreach_athlete;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during athlete's event results array initialization!]');
    END decathlon_results;

    bubble_sort(l_dcthl_pos);
    print_decathlon_positions(l_dcthl_pos);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(sqlerrm);
        dbms_output.put_line('Terminating code execution.');
END;
/