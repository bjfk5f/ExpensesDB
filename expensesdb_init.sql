--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.4

-- Started on 2019-11-05 09:49:42

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 239 (class 1255 OID 18336)
-- Name: add_month(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_month(mo character varying, y character varying)
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		mo varchar := $1;
		y varchar := $2;
		filepath varchar;
	BEGIN
		mo = TO_CHAR(TO_DATE(mo, 'MM'), 'Month');
		y = RIGHT(y, 2);
		filepath = concat('C:\tmp\Expenses - ', trim(mo), ' ', y, '.csv');
		EXECUTE
			format('COPY expenses(date, cost, category, description) FROM ''%s'' DELIMITER '','' CSV HEADER', filepath);
			
	END;

$_$;


ALTER PROCEDURE public.add_month(mo character varying, y character varying) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 21780)
-- Name: category_totals(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.category_totals(y integer) RETURNS TABLE(category character varying, january money, february money, march money, april money, may money, june money, july money, august money, september money, october money, november money, december money, total money)
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		y varchar := $1;
		months varchar[] = array['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
		mo varchar;
		category varchar;
		curr_cost money;
	BEGIN
		DROP TABLE IF EXISTS categories;
		CREATE temporary table categories(
			id serial,
			category varchar
		);
		DROP TABLE IF EXISTS february;
		CREATE temporary table february(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS march;
		CREATE temporary table march(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS april;
		CREATE temporary table april(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS june;
		CREATE temporary table june(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS july;
		CREATE temporary table july(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS august;
		CREATE temporary table august(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS september;
		CREATE temporary table september(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS october;
		CREATE temporary table october(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS november;
		CREATE temporary table november(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS december;
		CREATE temporary table december(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS january;
		CREATE temporary table january(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS may;
		CREATE temporary table may(
			category varchar,
			cost money
		);
		
		DROP TABLE IF EXISTS totals;
		CREATE temporary table totals(
			category varchar,
			cost money
		);
		EXECUTE
			'INSERT INTO categories(category) select distinct category from expenses where extract(year from date) = $1'
			USING y::integer;
		
		INSERT INTO categories(category) values ('Total');
		
		INSERT INTO totals(category, cost) select distinct expenses.category, 0 from expenses;
		
		FOREACH mo in array months
		LOOP
			EXECUTE format(
				'INSERT INTO %s(category, cost)
				select category, sum(sum(expenses.cost)) OVER (PARTITION BY (date_part(''month''::text, expenses.date)), expenses.category) AS cost
				from expenses
				where EXTRACT (month from date) = EXTRACT(MONTH FROM to_date($1, ''mon'')) AND extract (year from date) = EXTRACT(year from to_date($2, ''YYYY''))
				AND category != ''Total''
				GROUP BY (date_part(''month''::text, expenses.date)), expenses.category', mo)
				USING mo, y;
			
			EXECUTE format(
				'INSERT INTO %s(category, cost) 
				SELECT ''Total'', sum(cost)
				FROM %s', mo, mo);
				
			FOR category IN SELECT DISTINCT expenses.category FROM expenses
			LOOP
				EXECUTE format('SELECT cost FROM %s where category = ''%s''', mo, category)
				INTO curr_cost;
				IF curr_cost IS NOT NULL THEN
					EXECUTE 'UPDATE totals 
							 SET cost = cost + $1
							 WHERE category = $2'
					USING curr_cost, category;
				END IF;
			END LOOP;
		END LOOP;
		
		INSERT INTO totals(category, cost) select 'Total', sum(cost) from totals;
		
		EXECUTE format('DROP TABLE IF EXISTS temp_category_splits_%s', y);
		EXECUTE format('
		CREATE temporary TABLE temp_category_splits_%s(
			category varchar,
			january money,
			february money,
			march money,
			april money,
			may money,
			june money,
			july money,
			august money,
			september money,
			october money,
			november money,
			december money,
			Total money
		)', y);
		
		EXECUTE format('
		insert into temp_category_splits_%s
		select c.category, january.cost january, february.cost february, march.cost march, april.cost april, may.cost may, june.cost june, july.cost july, august.cost august, september.cost september, october.cost october, november.cost november, december.cost december, totals.cost Total
		from categories c
		full outer join january on c.category = january.category
		full outer join february on c.category = february.category
		full outer join march on c.category = march.category
		full outer join april on c.category = april.category
		full outer join may on c.category = may.category
		full outer join june on c.category = june.category
		full outer join july on c.category = july.category
		full outer join august on c.category = august.category
		full outer join september on c.category = september.category
		full outer join october on c.category = october.category
		full outer join november on c.category = november.category
		full outer join december on c.category = december.category
		full outer join totals on c.category = totals.category', y);
		
		return query EXECUTE format('select * from temp_category_splits_%s', y);
	END
$_$;


ALTER FUNCTION public.category_totals(y integer) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 18335)
-- Name: replace_month(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.replace_month(mo character varying, y character varying)
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		mo varchar := $1;
		y varchar := $2;
		filepath varchar;
	BEGIN
		EXECUTE
			'DELETE FROM expenses
			WHERE EXTRACT(month from date) = $1 AND EXTRACT(year from date) = $2'
			USING mo::integer, y::integer;
		mo = TO_CHAR(TO_DATE(mo, 'MM'), 'Month');
		y = RIGHT(y, 2);
		filepath = concat('C:\tmp\Expenses - ', trim(mo), ' ', y, '.csv');
		EXECUTE
			format('COPY expenses(date, cost, category, description) FROM ''%s'' DELIMITER '','' CSV HEADER', filepath);
			
	END;

$_$;


ALTER PROCEDURE public.replace_month(mo character varying, y character varying) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 19446)
-- Name: side_by_side_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.side_by_side_view(y integer) RETURNS TABLE(category character varying, january money, february money, march money, april money, may money, june money, july money, august money, september money, october money, november money, december money)
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		y varchar := $1;
		months varchar[] = array['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
		mo varchar;
	BEGIN
		DROP TABLE IF EXISTS categories;
		CREATE temporary table categories(
			id serial,
			category varchar
		);
		DROP TABLE IF EXISTS february;
		CREATE temporary table february(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS march;
		CREATE temporary table march(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS april;
		CREATE temporary table april(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS june;
		CREATE temporary table june(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS july;
		CREATE temporary table july(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS august;
		CREATE temporary table august(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS september;
		CREATE temporary table september(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS october;
		CREATE temporary table october(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS november;
		CREATE temporary table november(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS december;
		CREATE temporary table december(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS january;
		CREATE temporary table january(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS may;
		CREATE temporary table may(
			category varchar,
			cost money
		);
		
		EXECUTE
			'INSERT INTO categories(category) select distinct category from expenses where extract(year from date) = $1'
			USING y::integer;
		
		FOREACH mo in array months
		LOOP
			EXECUTE format(
				'INSERT INTO %s(category, cost)
				select category, sum(sum(expenses.cost)) OVER (PARTITION BY (date_part(''month''::text, expenses.date)), expenses.category) AS cost
				from expenses
				where EXTRACT (month from date) = EXTRACT(MONTH FROM to_date($1, ''mon'')) AND extract (year from date) = EXTRACT(year from to_date($2, ''YYYY''))
				GROUP BY (date_part(''month''::text, expenses.date)), expenses.category', mo)
				USING mo, y;
		END LOOP;
		
		EXECUTE format('DROP TABLE IF EXISTS temp_category_splits_%s', y);
		EXECUTE format('
		CREATE temporary TABLE temp_category_splits_%s(
			category varchar,
			january money,
			february money,
			march money,
			april money,
			may money,
			june money,
			july money,
			august money,
			september money,
			october money,
			november money,
			december money
		)', y);
		
		EXECUTE format('
		insert into temp_category_splits_%s
		select c.category, january.cost january, february.cost february, march.cost march, april.cost april, may.cost may, june.cost june, july.cost july, august.cost august, september.cost september, october.cost october, november.cost november, december.cost december
		from categories c
		full outer join january on c.category = january.category
		full outer join february on c.category = february.category
		full outer join march on c.category = march.category
		full outer join april on c.category = april.category
		full outer join may on c.category = may.category
		full outer join june on c.category = june.category
		full outer join july on c.category = july.category
		full outer join august on c.category = august.category
		full outer join september on c.category = september.category
		full outer join october on c.category = october.category
		full outer join november on c.category = november.category
		full outer join december on c.category = december.category', y);
		
		return query EXECUTE format('select * from temp_category_splits_%s', y);
	END
$_$;


ALTER FUNCTION public.side_by_side_view(y integer) OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 20328)
-- Name: split_totals(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.split_totals(y integer) RETURNS TABLE(category character varying, january money, february money, march money, april money, may money, june money, july money, august money, september money, october money, november money, december money)
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		y varchar := $1;
		months varchar[] = array['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
		mo varchar;
	BEGIN
		DROP TABLE IF EXISTS categories;
		CREATE temporary table categories(
			id serial,
			category varchar
		);
		DROP TABLE IF EXISTS february;
		CREATE temporary table february(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS march;
		CREATE temporary table march(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS april;
		CREATE temporary table april(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS june;
		CREATE temporary table june(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS july;
		CREATE temporary table july(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS august;
		CREATE temporary table august(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS september;
		CREATE temporary table september(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS october;
		CREATE temporary table october(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS november;
		CREATE temporary table november(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS december;
		CREATE temporary table december(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS january;
		CREATE temporary table january(
			category varchar,
			cost money
		);
		DROP TABLE IF EXISTS may;
		CREATE temporary table may(
			category varchar,
			cost money
		);
		
		EXECUTE
			'INSERT INTO categories(category) select distinct category from expenses where extract(year from date) = $1'
			USING y::integer;
		
		INSERT INTO categories(category) values ('Total');
		
		FOREACH mo in array months
		LOOP
			EXECUTE format(
				'INSERT INTO %s(category, cost)
				select category, sum(sum(expenses.cost)) OVER (PARTITION BY (date_part(''month''::text, expenses.date)), expenses.category) AS cost
				from expenses
				where EXTRACT (month from date) = EXTRACT(MONTH FROM to_date($1, ''mon'')) AND extract (year from date) = EXTRACT(year from to_date($2, ''YYYY''))
				AND category != ''Total''
				GROUP BY (date_part(''month''::text, expenses.date)), expenses.category', mo)
				USING mo, y;
			
			EXECUTE format(
				'INSERT INTO %s(category, cost) 
				SELECT ''Total'', sum(cost)
				FROM %s', mo, mo);
		END LOOP;
		
		EXECUTE format('DROP TABLE IF EXISTS temp_category_splits_%s', y);
		EXECUTE format('
		CREATE temporary TABLE temp_category_splits_%s(
			category varchar,
			january money,
			february money,
			march money,
			april money,
			may money,
			june money,
			july money,
			august money,
			september money,
			october money,
			november money,
			december money
		)', y);
		
		EXECUTE format('
		insert into temp_category_splits_%s
		select c.category, january.cost january, february.cost february, march.cost march, april.cost april, may.cost may, june.cost june, july.cost july, august.cost august, september.cost september, october.cost october, november.cost november, december.cost december
		from categories c
		full outer join january on c.category = january.category
		full outer join february on c.category = february.category
		full outer join march on c.category = march.category
		full outer join april on c.category = april.category
		full outer join may on c.category = may.category
		full outer join june on c.category = june.category
		full outer join july on c.category = july.category
		full outer join august on c.category = august.category
		full outer join september on c.category = september.category
		full outer join october on c.category = october.category
		full outer join november on c.category = november.category
		full outer join december on c.category = december.category', y);
		
		return query EXECUTE format('select * from temp_category_splits_%s', y);
	END
$_$;


ALTER FUNCTION public.split_totals(y integer) OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 22250)
-- Name: category_splits_2019; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.category_splits_2019 AS
 SELECT category_totals.category,
    category_totals.january,
    category_totals.february,
    category_totals.march,
    category_totals.april,
    category_totals.may,
    category_totals.june,
    category_totals.july,
    category_totals.august,
    category_totals.september,
    category_totals.october,
    category_totals.november,
    category_totals.december,
    category_totals.total
   FROM public.category_totals(2019) category_totals(category, january, february, march, april, may, june, july, august, september, october, november, december, total);


ALTER TABLE public.category_splits_2019 OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 23217)
-- Name: category_splits_2020; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.category_splits_2020 AS
 SELECT category_totals.category,
    category_totals.january,
    category_totals.february,
    category_totals.march,
    category_totals.april,
    category_totals.may,
    category_totals.june,
    category_totals.july,
    category_totals.august,
    category_totals.september,
    category_totals.october,
    category_totals.november,
    category_totals.december,
    category_totals.total
   FROM public.category_totals(2020) category_totals(category, january, february, march, april, may, june, july, august, september, october, november, december, total);


ALTER TABLE public.category_splits_2020 OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 205 (class 1259 OID 18295)
-- Name: expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expenses (
    transaction_id integer NOT NULL,
    date date,
    cost money,
    category character varying,
    description character varying
);


ALTER TABLE public.expenses OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 18293)
-- Name: expenses_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expenses_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.expenses_transaction_id_seq OWNER TO postgres;

--
-- TOC entry 2916 (class 0 OID 0)
-- Dependencies: 204
-- Name: expenses_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expenses_transaction_id_seq OWNED BY public.expenses.transaction_id;


--
-- TOC entry 206 (class 1259 OID 18320)
-- Name: monthly_category_totals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.monthly_category_totals AS
 SELECT date_part('year'::text, expenses.date) AS year,
    date_part('month'::text, expenses.date) AS month,
    expenses.category,
    sum(sum(expenses.cost)) OVER (PARTITION BY (date_part('month'::text, expenses.date)), expenses.category) AS total
   FROM public.expenses
  GROUP BY (date_part('year'::text, expenses.date)), (date_part('month'::text, expenses.date)), expenses.category
  ORDER BY (date_part('year'::text, expenses.date)), (date_part('month'::text, expenses.date)), (sum(sum(expenses.cost)) OVER (PARTITION BY (date_part('month'::text, expenses.date)), expenses.category)) DESC;


ALTER TABLE public.monthly_category_totals OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 19438)
-- Name: monthly_totals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.monthly_totals AS
 SELECT date_part('year'::text, expenses.date) AS year,
    to_char(to_timestamp((date_part('month'::text, expenses.date))::text, 'MM'::text), 'Month'::text) AS month,
    sum(sum(expenses.cost)) OVER (PARTITION BY (date_part('month'::text, expenses.date))) AS total
   FROM public.expenses
  GROUP BY (date_part('year'::text, expenses.date)), (date_part('month'::text, expenses.date))
  ORDER BY (date_part('year'::text, expenses.date)), (date_part('month'::text, expenses.date)), (sum(sum(expenses.cost)) OVER (PARTITION BY (date_part('month'::text, expenses.date)))) DESC;


ALTER TABLE public.monthly_totals OWNER TO postgres;

--
-- TOC entry 2781 (class 2604 OID 18298)
-- Name: expenses transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses ALTER COLUMN transaction_id SET DEFAULT nextval('public.expenses_transaction_id_seq'::regclass);



--
-- TOC entry 2783 (class 2606 OID 18303)
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (transaction_id);


-- Completed on 2019-11-05 09:49:43

--
-- PostgreSQL database dump complete
--

