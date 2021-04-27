SET SERVEROUTPUT ON;

SET VERIFY OFF;

CREATE OR REPLACE PACKAGE exceptions_pkg IS
    /* EXCEPTIONS */
    ex_bad_init_code CONSTANT PLS_INTEGER := -20001;
    ex_bad_init EXCEPTION;
    PRAGMA exception_init ( ex_bad_init, -20001 );
    ex_nl_missing_code CONSTANT PLS_INTEGER := -20002;
    ex_nl_missing EXCEPTION;
    PRAGMA exception_init ( ex_nl_missing, -20002 );
    ex_negative_results_code CONSTANT PLS_INTEGER := -20003;
    ex_negative_results EXCEPTION;
    PRAGMA exception_init ( ex_negative_results, -20003 );
    /* END OF EXCEPTIONS */
END exceptions_pkg;
/

CREATE OR REPLACE PACKAGE error_pkg IS
    /* TYPES */
    TYPE error_context_rt IS RECORD (
        module_owner  error_log.module_owner%TYPE,
        module_name   error_log.module_name%TYPE,
        error_line    error_log.error_line%TYPE
    );
    /* END OF TYPES */
    
    /* MODULE DECLARATIONS */
    PROCEDURE insert_error (
        i_code     IN  error_message.code%TYPE,
        i_message  IN  error_message.message%TYPE
    );

    FUNCTION parse_error_context (
        i_err_msg IN VARCHAR2
    ) RETURN error_context_rt;

    FUNCTION select_error_message (
        i_err_code IN PLS_INTEGER
    ) RETURN VARCHAR2;

    PROCEDURE record_error;

    PROCEDURE print_error;
    /* END OF MODULE DECLARATIONS */
END error_pkg;
/

CREATE OR REPLACE PACKAGE BODY error_pkg IS
    /* MODULES */
    PROCEDURE insert_error (
        i_code     IN  error_message.code%TYPE,
        i_message  IN  error_message.message%TYPE
    ) IS
    BEGIN
        INSERT INTO error_message (
            code,
            message
        ) VALUES (
            i_code,
            i_message
        );

    END insert_error;

    FUNCTION init_error_context (
        i_module_owner  IN  error_log.module_owner%TYPE,
        i_module_name   IN  error_log.module_name%TYPE,
        i_error_line    IN  error_log.error_line%TYPE
    ) RETURN error_context_rt IS
        l_err_ctx error_context_rt;
    BEGIN
        l_err_ctx.module_owner := i_module_owner;
        l_err_ctx.module_name := i_module_name;
        l_err_ctx.error_line := i_error_line;
        RETURN l_err_ctx;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(q'[Error during error's context record initialization!]');
    END init_error_context;

    FUNCTION parse_error_context (
        i_err_msg IN VARCHAR2
    ) RETURN error_context_rt IS

        c_quotation_pattern  CONSTANT CHAR(9) := '\"(.*?)\"';
        c_line_pattern       CONSTANT CHAR(5) := 'line';
        c_word_pattern       CONSTANT CHAR(8) := '[^\"\.]+';
        l_err_ctx            error_context_rt;
        l_temp               VARCHAR2(61);
        l_temp2              VARCHAR2(500);
    BEGIN
        l_temp2 := substr(i_err_msg, instr(i_err_msg, c_line_pattern) + length(c_line_pattern), instr(i_err_msg, chr(13)) - 2);

        l_temp := regexp_substr(i_err_msg, c_quotation_pattern);
        l_err_ctx := init_error_context(i_module_owner => regexp_substr(l_temp, c_word_pattern, occurrence => 1),
                                       i_module_name => regexp_substr(l_temp, c_word_pattern, occurrence => 2),
                                       i_error_line => substr(regexp_substr(i_err_msg, 'line \d+'), length(c_line_pattern) + 1));

        RETURN l_err_ctx;
    END parse_error_context;

    FUNCTION select_error_message (
        i_err_code IN PLS_INTEGER
    ) RETURN VARCHAR2 IS
        l_err_msg error_message.message%TYPE;
    BEGIN
        SELECT
            message
        INTO l_err_msg
        FROM
            error_message
        WHERE
            code = i_err_code;

        RETURN l_err_msg;
    EXCEPTION
        WHEN no_data_found THEN
            l_err_msg := sqlerrm(i_err_code);
            RETURN l_err_msg;
    END select_error_message;

    PROCEDURE record_error IS

        l_rtt_trace  VARCHAR2(2000);
        l_err_ctx    error_context_rt;
        l_code       error_message.code%TYPE;
        l_message    error_message.message%TYPE;
        PRAGMA autonomous_transaction;
    BEGIN
        l_rtt_trace := dbms_utility.format_error_backtrace;
        l_err_ctx := parse_error_context(l_rtt_trace);
        l_code := sqlcode;
        l_message := select_error_message(l_code);
        INSERT INTO error_log (
            module_owner,
            module_name,
            error_line,
            module_user,
            created_on,
            code,
            message
        ) VALUES (
            l_err_ctx.module_owner,
            l_err_ctx.module_name,
            l_err_ctx.error_line,
            user,
            current_timestamp,
            l_code,
            l_message
        );

        COMMIT;
    END record_error;

    PROCEDURE print_error IS
        l_rtt_trace  VARCHAR2(2000);
        l_err_ctx    error_context_rt;
        l_message    error_log.message%TYPE;
    BEGIN
        l_rtt_trace := dbms_utility.format_error_backtrace;
        l_err_ctx := parse_error_context(l_rtt_trace);
        l_message := select_error_message(sqlcode);
        dbms_output.put_line('---ERROR HEADER---');
        dbms_output.put_line('code: ' || sqlcode);
        dbms_output.put_line('message: ' || l_message);
        dbms_output.put_line('module user: ' || user);
        dbms_output.put_line('module owner: ' || l_err_ctx.module_owner);
        dbms_output.put_line('module name: ' || l_err_ctx.module_name);
        dbms_output.put_line('error line: ' || l_err_ctx.error_line);
        dbms_output.put_line('---END OF ERROR---');
    END print_error;
    /* END OF MODULES */
END error_pkg;
/

CREATE OR REPLACE PACKAGE globals_pkg IS
    /* TYPES */
    SUBTYPE name_t IS VARCHAR2(35);
    SUBTYPE whole_num_t IS NUMBER(5, 0);
    SUBTYPE point_t IS PLS_INTEGER;
    SUBTYPE event_t IS points_system.event%TYPE;
    SUBTYPE result_t IS points_system.a%TYPE;
    SUBTYPE points_system_t IS points_system%rowtype;
    SUBTYPE text_t IS VARCHAR2(32767);
    /* END OF TYPES */
END globals_pkg;
/

CREATE OR REPLACE PACKAGE decathlon_pkg IS
    /* TYPES */
    TYPE athlete_points_rt IS RECORD (
        athlete  globals_pkg.name_t,
        points   globals_pkg.whole_num_t
    );
    TYPE event_results_vt IS
        VARRAY(10) OF globals_pkg.result_t;
    TYPE athlete_results_rt IS RECORD (
        athlete  globals_pkg.name_t,
        ev_res   event_results_vt
    );
    TYPE points_system_vt IS
        VARRAY(10) OF globals_pkg.points_system_t;
    TYPE decathlon_positions_nt IS
        TABLE OF athlete_points_rt;
    TYPE athletes_results_nt IS
        TABLE OF athlete_results_rt NOT NULL;
    TYPE event_dictionary_at IS
        TABLE OF PLS_INTEGER INDEX BY globals_pkg.event_t;
    TYPE event_order_vt IS
        VARRAY(10) OF globals_pkg.event_t;
    /* END OF TYPES */
    
    /* MODULE DECLARATIONS */
    FUNCTION init_athlete_points (
        i_athlete  IN  globals_pkg.name_t,
        i_points   IN  globals_pkg.point_t
    ) RETURN athlete_points_rt;

    FUNCTION init_athlete_results (
        i_athlete  IN  globals_pkg.name_t,
        i_ev_res   IN  event_results_vt
    ) RETURN athlete_results_rt;

    PROCEDURE sort_points (
        io_dcthl_pos IN OUT NOCOPY decathlon_positions_nt
    );

    PROCEDURE print_decathlon_positions (
        i_dcthl_pos IN decathlon_positions_nt
    );

    FUNCTION calculate_points (
        i_ev_sys    IN  globals_pkg.points_system_t,
        i_ev_res    IN  event_results_vt,
        i_ev_index  IN  PLS_INTEGER
    ) RETURN globals_pkg.point_t;

    FUNCTION calculate_positions (
        i_pnts_sys   IN  points_system_vt,
        i_athls_res  IN  athletes_results_nt,
        i_ev_order   IN  event_order_vt
    ) RETURN decathlon_positions_nt;
    /* END OF MODULE DECLARATIONS */
END decathlon_pkg;
/

CREATE OR REPLACE PACKAGE BODY decathlon_pkg IS
    /* MODULES */
    FUNCTION init_athlete_points (
        i_athlete  IN  globals_pkg.name_t,
        i_points   IN  globals_pkg.point_t
    ) RETURN athlete_points_rt IS
        l_athl_pnts athlete_points_rt;
    BEGIN
        IF i_athlete = '' OR i_points < 0 THEN
            RAISE exceptions_pkg.ex_bad_init;
        END IF;
        l_athl_pnts.athlete := i_athlete;
        l_athl_pnts.points := i_points;
        RETURN l_athl_pnts;
    EXCEPTION
        WHEN exceptions_pkg.ex_bad_init THEN
            error_pkg.record_error();
            error_pkg.print_error();
            RAISE;
    END init_athlete_points;

    FUNCTION init_athlete_results (
        i_athlete  IN  globals_pkg.name_t,
        i_ev_res   IN  event_results_vt
    ) RETURN athlete_results_rt IS
        l_athl_res athlete_results_rt;
    BEGIN
        IF i_athlete = '' OR i_ev_res IS NULL THEN
            RAISE exceptions_pkg.ex_bad_init;
        END IF;
        l_athl_res.athlete := i_athlete;
        l_athl_res.ev_res := i_ev_res;
        RETURN l_athl_res;
    EXCEPTION
        WHEN exceptions_pkg.ex_bad_init THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END init_athlete_results;

    PROCEDURE sort_points (
        io_dcthl_pos IN OUT NOCOPY decathlon_positions_nt
    ) IS
        l_temp         athlete_points_rt;
        l_right_index  PLS_INTEGER;
        l_arr_index    PLS_INTEGER;
    BEGIN
        /* BUBBLE SORT */
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
        /* END OF BUBBLE SORT */
    EXCEPTION
        WHEN collection_is_null THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END sort_points;

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
        WHEN collection_is_null THEN
            error_pkg.record_error;
            error_pkg.print_error;
    END print_decathlon_positions;

    FUNCTION init_event_to_index_dict (
        i_pnts_sys IN points_system_vt
    ) RETURN event_dictionary_at IS
        l_ev_dict event_dictionary_at;
    BEGIN
        FOR ev_index IN i_pnts_sys.first..i_pnts_sys.last LOOP
            l_ev_dict(i_pnts_sys(ev_index).event) := ev_index;
        END LOOP;

        RETURN l_ev_dict;
    END init_event_to_index_dict;

    FUNCTION calculate_points (
        i_ev_sys    IN  globals_pkg.points_system_t,
        i_ev_res    IN  event_results_vt,
        i_ev_index  IN  PLS_INTEGER
    ) RETURN globals_pkg.point_t IS
        l_error  globals_pkg.point_t;
        l_point  globals_pkg.point_t;
    BEGIN
        IF i_ev_res(i_ev_index) < 0 THEN
            RAISE exceptions_pkg.ex_negative_results;
        END IF;
        l_error := 1;
        l_point := 0;
        CASE i_ev_sys.unit
            WHEN 'seconds' THEN
                l_point := trunc(i_ev_sys.a * power(i_ev_sys.b - i_ev_res(i_ev_index), i_ev_sys.c), 0);
            WHEN 'metres' THEN
                IF i_ev_sys.event IN ( 'Long jump', 'High jump', 'Pole vault' ) THEN
                    l_error := 100;
                END IF;

                l_point := trunc(i_ev_sys.a * power(i_ev_res(i_ev_index) * l_error - i_ev_sys.b, i_ev_sys.c), 0);

            ELSE
                dbms_output.put_line('Error! No such decathlon event exists.');
        END CASE;

        --dbms_output.put_line(l_point);
        RETURN l_point;
    EXCEPTION
        WHEN exceptions_pkg.ex_negative_results OR subscript_outside_limit OR subscript_beyond_count OR collection_is_null THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END calculate_points;

    FUNCTION calculate_positions (
        i_pnts_sys   IN  points_system_vt,
        i_athls_res  IN  athletes_results_nt,
        i_ev_order   IN  event_order_vt
    ) RETURN decathlon_positions_nt IS
        l_ev_dict    event_dictionary_at;
        l_ev_res     event_results_vt;
        l_points     globals_pkg.point_t;
        l_ev_sys     globals_pkg.points_system_t;
        l_dcthl_pos  decathlon_positions_nt;
    BEGIN
        l_ev_dict := init_event_to_index_dict(i_pnts_sys);
        l_dcthl_pos := decathlon_positions_nt();
        << foreach_athlete >> FOR ath_index IN i_athls_res.first..i_athls_res.last LOOP
            l_ev_res := i_athls_res(ath_index).ev_res;
            l_points := 0;
            << foreach_event >> FOR ev_index IN l_ev_res.first..l_ev_res.last LOOP
                l_ev_sys := i_pnts_sys(l_ev_dict(i_ev_order(ev_index)));
                l_points := l_points + calculate_points(l_ev_sys, l_ev_res, ev_index);
            END LOOP foreach_event;
            
            --dbms_output.put_line('ATHLETE: ' || i_athls_res(i).athlete || ' POINTS: ' || l_points);
            l_dcthl_pos.extend();
            l_dcthl_pos(ath_index) := init_athlete_points(i_athlete => i_athls_res(ath_index).athlete, i_points => l_points);

        END LOOP foreach_athlete;

        RETURN l_dcthl_pos;
    EXCEPTION
        WHEN OTHERS THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END calculate_positions;
    /* END OF MODULES */
END decathlon_pkg;
/

CREATE OR REPLACE PACKAGE utilities_pkg IS
    /* MODULE DECLARATIONS */
    FUNCTION init_points_system RETURN decathlon_pkg.points_system_vt;

    FUNCTION parse_athletes_results (
        i_input_data IN globals_pkg.text_t
    ) RETURN decathlon_pkg.athletes_results_nt;
    /* END OF MODULE DECLARATIONS */
END utilities_pkg;
/

CREATE OR REPLACE PACKAGE BODY utilities_pkg IS
    /* MODULES */
    FUNCTION init_points_system RETURN decathlon_pkg.points_system_vt IS
        l_pnts_sys decathlon_pkg.points_system_vt;
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

        RETURN l_pnts_sys;
    EXCEPTION
        WHEN no_data_found THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END init_points_system;

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

    FUNCTION parse_athletes_results (
        i_input_data IN globals_pkg.text_t
    ) RETURN decathlon_pkg.athletes_results_nt IS

        c_new_line           CONSTANT CHAR := chr(13);
        c_result_delimiter   CONSTANT CHAR := ';';
        c_name_delimiter     CONSTANT CHAR(3) := ' - ';
        c_decimal_separator  CONSTANT CHAR(2) := '\.';
        c_number_pattern     CONSTANT CHAR(8) := '\d+\.\d+';
        c_number_mask        CONSTANT CHAR(5) := '99.99';
        l_athls_res          decathlon_pkg.athletes_results_nt;
        l_text               globals_pkg.text_t;
        l_ev_res             decathlon_pkg.event_results_vt;
        l_count              PLS_INTEGER;
        l_results            globals_pkg.text_t;
        l_name               globals_pkg.name_t;
    BEGIN
        IF i_input_data = '' THEN
            RAISE exceptions_pkg.ex_bad_init;
        END IF;
        l_athls_res := decathlon_pkg.athletes_results_nt();
        l_text := i_input_data;
        l_count := regexp_count(l_text, c_new_line);
        IF l_count = 0 THEN
            RAISE exceptions_pkg.ex_nl_missing;
        END IF;
        << foreach_athlete_results >> FOR ath_index IN 1..l_count LOOP
            l_results := prior_pattern(l_text, c_new_line);
            l_text := start_pattern(l_text, c_new_line, i_offset => 1);
            l_name := prior_pattern(l_results, c_name_delimiter);
            l_results := start_pattern(l_results, c_number_pattern);
            l_ev_res := decathlon_pkg.event_results_vt();
            FOR res_index IN 1..9 LOOP
                l_ev_res.extend();
                l_ev_res(res_index) := to_number(prior_pattern(l_results, c_result_delimiter), c_number_mask);
                l_results := start_pattern(l_results, c_result_delimiter, 1);
            END LOOP;

            l_ev_res.extend();
            l_ev_res(10) := to_number(prior_pattern(l_results, c_decimal_separator)) * 60 + to_number(start_pattern(l_results, c_decimal_separator,
            1), c_number_mask);

            l_athls_res.extend();
            l_athls_res(ath_index) := decathlon_pkg.init_athlete_results(i_athlete => l_name, i_ev_res => l_ev_res);

        END LOOP foreach_athlete_results;

        RETURN l_athls_res;
    EXCEPTION
        WHEN exceptions_pkg.ex_nl_missing OR exceptions_pkg.ex_bad_init OR value_error THEN
            error_pkg.record_error;
            error_pkg.print_error;
            RAISE;
    END parse_athletes_results;
    /* END OF MODULES */
END utilities_pkg;
/