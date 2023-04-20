--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.26
-- Dumped by pg_dump version 9.5.5

-- Started on 2020-09-09 20:30:19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12723)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3304 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 594 (class 1247 OID 16459)
-- Name: nserv_result; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE nserv_result AS (
	atendidas bigint,
	natendidas bigint,
	o_serv double precision,
	o_fila double precision,
	i_fila double precision,
	tot_chamadas double precision,
	tp_n_serv character varying,
	datenow timestamp with time zone
);


ALTER TYPE nserv_result OWNER TO postgres;

--
-- TOC entry 597 (class 1247 OID 16462)
-- Name: rel_not_result; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE rel_not_result AS (
	virtual_grp character varying,
	intervalo time without time zone,
	t_lig bigint,
	atendidas bigint,
	t_t_falado interval,
	abandonadas bigint,
	maior interval,
	medio interval,
	_20 bigint,
	m_20 bigint,
	a_20 bigint,
	a_m_20 bigint,
	a_30 bigint,
	a_m_30 bigint,
	aa_30 bigint,
	aa_m_30 bigint
);


ALTER TYPE rel_not_result OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 16463)
-- Name: n_serv(timestamp without time zone, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION n_serv(timestamp without time zone, timestamp without time zone, text) RETURNS nserv_result
    LANGUAGE sql
    AS $_$ SELECT
	(select count(atendida) FROM tb_chamadas where 
		acd_start > $1 and acd_start < $2 and virtual_group like $3 and modo='UV' and atendida = true),
	(select count(atendida) FROM tb_chamadas where
		acd_start > $1 and acd_start < $2 and virtual_group like $3 and date_end is not null and agente_start is null and
		modo='UV' and atendida = False ),
	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (SELECT virtual_group FROM tb_virtual_groups) and
	((agente_end - agente_start) <= (
		select o_serv from tb_virtual_groups where tb_virtual_groups.virtual_group = tb_chamadas.virtual_group)
	 and atendida=True and acd_start > $1 and acd_start < $2 and virtual_group like $3 )),
	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (
		SELECT virtual_group FROM tb_virtual_groups) and ((date_end - acd_start) >= (
		select o_fila from tb_virtual_groups where tb_virtual_groups.virtual_group = tb_chamadas.virtual_group) and atendida=FALSE 
		) and acd_start > $1 and acd_start < $2 and virtual_group like $3),
		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (
		SELECT virtual_group FROM tb_virtual_groups) and ((date_end - acd_start) <= (
		select o_fila from tb_virtual_groups where tb_virtual_groups.virtual_group = tb_chamadas.virtual_group) and atendida=FALSE 
		) and acd_start > $1 and acd_start < $2 and virtual_group like $3),
		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in 
		(SELECT virtual_group FROM tb_virtual_groups) and acd_start > $1 and acd_start < $2 and virtual_group like $3)
		 ,(select valor from infos where tipo = '2'),(select NOW())
	
 $_$;


ALTER FUNCTION public.n_serv(timestamp without time zone, timestamp without time zone, text) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16464)
-- Name: n_serv_ani(timestamp without time zone, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION n_serv_ani(timestamp without time zone, timestamp without time zone, text) RETURNS nserv_result
    LANGUAGE sql
    AS $_$ SELECT
	(select count(atendida) from tb_chamadas where outgoing_call=$3 and date_start > $1 and date_start < $2 and atendida = true and date_end is not null and modo = 'UV'),
	(select count(atendida) from tb_chamadas where outgoing_call=$3 and date_start > $1 and date_start < $2 and atendida = false and date_end is not null and modo = 'UV'),
	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (SELECT virtual_group FROM tb_virtual_groups) and
	((agente_start - acd_start) <= (
		select o_fila from tb_virtual_groups where tb_virtual_groups.virtual_group = tb_chamadas.virtual_group)
	 and atendida=True and acd_start > $1 and acd_start < $2 and outgoing_call like $3 )),
	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where ((date_end - acd_start) >= ('00:00:20') and atendida=FALSE 
		) and acd_start > $1 and acd_start < $2 and date_end is not null and outgoing_call like $3),
		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (
		SELECT virtual_group FROM tb_virtual_groups) and ((date_end - acd_start) <= ('00:00:20') and atendida=FALSE 
		) and acd_start > $1 and acd_start < $2 and outgoing_call=$3 and date_end is not null),
		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in 
		(SELECT virtual_group FROM tb_virtual_groups) and acd_start > $1 and acd_start < $2 and outgoing_call like $3)
		 ,(select valor from infos where tipo = '2'),(select NOW())
	
 $_$;


ALTER FUNCTION public.n_serv_ani(timestamp without time zone, timestamp without time zone, text) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16465)
-- Name: rel_agentes(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_agentes(text) RETURNS TABLE(n_agente character varying, id integer, date date, atendidas bigint, tma interval, ttf interval, tempo_intervalo interval, tempo_refe interval)
    LANGUAGE plpgsql ROWS 100000
    AS $_$
  BEGIN
 RETURN QUERY 
select DISTINCT(a.n_agente),
(select tb_agentes.id from tb_agentes where tb_agentes.n_agente = a.n_agente order by tb_agentes.id limit 1),
(select date ($1)),
(select count(callid) from tb_billing where atendente=a.n_agente and data_abandono is NULL and data_sistema= date ($1)),
(select sum(tempo_chamada)/count(callid) from tb_billing where atendente=a.n_agente and data_abandono is NULL and data_sistema= date ($1)),
(select sum(tempo_chamada) from tb_billing where atendente=a.n_agente and data_abandono is NULL and data_sistema= date ($1)),
(select sum(data_fim - data_ini) from tb_agente_log where 
agente in (select tb_agentes.id from tb_agentes where tb_agentes.n_agente=a.n_agente ) and data_ini > date ($1) and data_ini < date ($1) + time '23:59:59' and tipo=5 and cast(tp_pausa as int) >= 2) as intervalo,
(select sum(data_fim - data_ini) from tb_agente_log where 
agente in (select tb_agentes.id from tb_agentes where tb_agentes.n_agente=a.n_agente ) and data_ini > date ($1) and data_ini < date ($1) + time '23:59:59' and tipo=5 and cast(tp_pausa as int) <= 2) as refeicao 
 from tb_agentes as a where ativo = true group by a.id,a.n_agente;

  RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_agentes(text) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16466)
-- Name: rel_billing(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_billing(text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf text, virtual_grp character varying, n_agente character varying, tab_1 text, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, dur_fila interval)
    LANGUAGE plpgsql ROWS 1
    AS $_$
  BEGIN
 RETURN QUERY 

select DISTINCT(a.channel),count(a.channel),
(select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.uniqueid from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.ani from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.dnis from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.extension from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.outgoing_call from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1 ),

case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.virtual_group is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1 )
 else NULL end as virtual_transf, 
case WHEN (count(a.channel)) > 1 THEN 
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and tb_chamadas.agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.agente_start from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as date_agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.tab_1 || '-'|| tb_chamadas.tab_2 from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as Tab1_transf,
 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.tab_1 || '-'|| tb_chamadas.tab_2 from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),

case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) = 'UV' THEN
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
else
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
 end as Dur_total,






(select tb_chamadas.h_agente from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1),
(select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1),
(select tb_chamadas.atendida from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1 ),

case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) = 'UV' THEN
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_end desc limit 1) - 
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1))
else
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_end desc limit 1) - 
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_start limit 1))
 end as Dur_total,



case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.outgoing_call from tb_chamadas,tb_agentes where tb_chamadas.modo like 'T%' and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as tranf_ext,

case WHEN ((select tb_chamadas.atendida from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1 )) = True THEN
(select tb_chamadas.agente_start - tb_chamadas.acd_start  from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
else
(select tb_chamadas.date_end - tb_chamadas.acd_start  from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
end

from tb_chamadas as a where a.date_start > date ($1) and a.date_start < date ($1) + time '23:59:59' group by a.channel order by date_start;



   RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_billing(text) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16467)
-- Name: rel_billing_h(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_billing_h(text, text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf text, virtual_grp character varying, n_agente character varying, tab_1 text, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, dur_fila interval)
    LANGUAGE plpgsql ROWS 1
    AS $_$
  BEGIN
 RETURN QUERY 

select DISTINCT(a.channel),count(a.channel),
(select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),
(select tb_chamadas.uniqueid from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),
(select tb_chamadas.ani from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),
(select tb_chamadas.dnis from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2)  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.extension from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2)  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.outgoing_call from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2)  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1 ),

case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.virtual_group is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1 )
 else NULL end as virtual_transf, 
case WHEN (count(a.channel)) > 1 THEN 
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and tb_chamadas.agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1)
 else NULL end as agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.agente_start from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1)
 else NULL end as date_agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.tab_1 || '-'|| tb_chamadas.tab_2 from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1)
 else NULL end as Tab1_transf,
 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),
(select tb_chamadas.tab_1 || '-'|| tb_chamadas.tab_2 from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1),

case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1) = 'UV' THEN
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1)
else
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1)
 end as Dur_total,






(select tb_chamadas.h_agente from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1),
(select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1),
(select tb_chamadas.atendida from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1 ),

case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1) = 'UV' THEN
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by date_end desc limit 1) - 
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1))
else
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by date_end desc limit 1) - 
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by date_start limit 1))
 end as Dur_total,



case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.outgoing_call from tb_chamadas,tb_agentes where tb_chamadas.modo like 'T%' and tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start desc limit 1)
 else NULL end as tranf_ext,

case WHEN ((select tb_chamadas.atendida from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1 )) = True THEN
(select tb_chamadas.agente_start - tb_chamadas.acd_start  from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1)
else
(select tb_chamadas.date_end - tb_chamadas.acd_start  from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start >= date ($1) and tb_chamadas.date_start < date ($2) order by tb_chamadas.date_start limit 1)
end

from tb_chamadas as a where a.date_start >= date ($1) and a.date_start < date ($2) group by a.channel order by date_start;



   RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_billing_h(text, text) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16468)
-- Name: rel_billing_new(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_billing_new(text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf character varying, virtual_grp character varying, n_agente character varying, tab_1 character varying, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, abandonada_menor_20 integer, abandonada_maior_20 integer, atendida_menor_20 integer, atendida_maior_20 integer, abandonada_menor_30 integer, abandonada_maior_30 integer, atendida_menor_30 integer, atendida_maior_30 integer)
    LANGUAGE plpgsql ROWS 1
    AS $_$
  BEGIN
 RETURN QUERY 

select DISTINCT(a.channel),count(a.channel),
(select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.uniqueid from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.ani from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.dnis from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.extension from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.outgoing_call from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59'  order by tb_chamadas.date_start limit 1),
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1 ),

case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.virtual_group is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1 )
 else NULL end as virtual_transf, 
case WHEN (count(a.channel)) > 1 THEN 
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and tb_chamadas.agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.agente_start from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as date_agente_transf,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.tab_1 from tb_chamadas,tb_agentes where tb_chamadas.virtual_group is not NULL and agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as Tab1_transf,
 
(select tb_chamadas.virtual_group from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_agentes.n_agente from tb_chamadas,tb_agentes where agente=id and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.tab_1 from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),

case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) = 'UV' THEN
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
else
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1)
 end as Dur_total,
(select tb_chamadas.h_agente from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1),
(select tb_chamadas.atendida from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1 ),
case WHEN (select tb_chamadas.modo from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) = 'UV' THEN
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_end desc limit 1) - 
(select tb_chamadas.agente_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1))
else
((select tb_chamadas.date_end from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_end desc limit 1) - 
(select tb_chamadas.date_start from tb_chamadas where tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by date_start limit 1))
 end as Dur_total,
case WHEN (count(a.channel)) > 1 THEN 
(select tb_chamadas.outgoing_call from tb_chamadas,tb_agentes where tb_chamadas.modo like 'T%' and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start desc limit 1)
 else NULL end as tranf_ext,

(select case WHEN (tb_chamadas.date_end - tb_chamadas.acd_start) < time '00:00:20' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=false and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,

(select case WHEN (tb_chamadas.date_end - tb_chamadas.acd_start) > time '00:00:20' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=false and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,


(select case WHEN (tb_chamadas.agente_start - tb_chamadas.acd_start) < time '00:00:20' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=true and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,

(select case WHEN (tb_chamadas.agente_start - tb_chamadas.acd_start) > time '00:00:20' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=true and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,

(select case WHEN (tb_chamadas.date_end - tb_chamadas.acd_start) < time '00:00:30' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=false and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,
(select case WHEN (tb_chamadas.date_end - tb_chamadas.acd_start) > time '00:00:30' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=false and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,

(select case WHEN (tb_chamadas.agente_start - tb_chamadas.acd_start) < time '00:00:30' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=true and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) ,

(select case WHEN (tb_chamadas.agente_start - tb_chamadas.acd_start) > time '00:00:30' THEN 1 else 0 end from tb_chamadas 
where tb_chamadas.modo='UV' and tb_chamadas.atendida=true and tb_chamadas.acd_start is not NULL and tb_chamadas.channel=a.channel and tb_chamadas.date_start > date ($1) and tb_chamadas.date_start < date ($1) + time '23:59:59' order by tb_chamadas.date_start limit 1) 

 
from tb_chamadas as a where a.date_start > date ($1) and a.date_start < date ($1) + time '23:59:59' group by a.channel order by date_start;
   RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_billing_new(text) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16469)
-- Name: rel_noturno(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_noturno(text) RETURNS TABLE(virtual_grp character varying, intervalo time without time zone, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior interval, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
    LANGUAGE plpgsql ROWS 100000
    AS $_$
  BEGIN
 RETURN QUERY 
 SELECT virtual_group,tb_interval_rel.intervalo,
 (SELECT count(DISTINCT(channel))  from tb_chamadas 
 where tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as T_lig, 
 (SELECT count(DISTINCT(channel)) from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as atendidas, 
 (SELECT sum(agente_end - agente_start)/count(DISTINCT(channel))  from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as t_t_falado,  
 (SELECT count(DISTINCT(channel))
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as abandonadas, 
 (SELECT max(date_end - acd_start)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as Maior, 
 (SELECT sum(date_end - acd_start)/count(DISTINCT(channel)) 
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as Medio, 
 (SELECT sum(case WHEN (date_end - acd_start) < time '00:00:20' THEN 1 else 0 end)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as _20,  
 (SELECT sum(case WHEN (date_end - acd_start) > time '00:00:20' THEN 1 else 0 end)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as m_20,
 (SELECT sum(case WHEN (agente_start - acd_start) < time '00:00:20' THEN 1 else 0 end ) 
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_20,   
 (SELECT sum(case WHEN (agente_start - acd_start) > time '00:00:20' THEN 1 else 0 end)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_m_20,  
 (SELECT sum(case WHEN (agente_start - acd_start) < time '00:00:30' THEN 1 else 0 end ) from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_30,
 (SELECT sum(case WHEN (agente_start - acd_start) > time '00:00:30' THEN 1 else 0 end)  from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_m_30,  
  (SELECT sum(case WHEN (date_end - acd_start) < time '00:00:30' THEN 1 else 0 end)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as _30,  
 (SELECT sum(case WHEN (date_end - acd_start) > time '00:00:30' THEN 1 else 0 end)  
 from tb_chamadas where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and acd_start is not NULL and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as m_30,
 (SELECT count(DISTINCT(channel))  from tb_chamadas 
 where tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='S' and date_start BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as T_lig_out
  FROM tb_interval_rel,tb_virtual_groups order by tb_virtual_groups.virtual_group,tb_interval_rel.intervalo;
  RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_noturno(text) OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16470)
-- Name: rel_noturno_bil(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_noturno_bil(text) RETURNS TABLE(virtual_grp character varying, intervalo time without time zone, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior time without time zone, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
    LANGUAGE plpgsql ROWS 100000
    AS $_$
  BEGIN
 RETURN QUERY 
SELECT virtual_group,tb_interval_rel.intervalo,
 (SELECT count(callid)  from tb_billing 
 where grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and (data_sistema + hora_sistema) BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as T_lig, 
 (SELECT count(callid) from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null  and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as atendidas, 
 (SELECT sum(tempo_chamada)/count(DISTINCT(callid))  from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is  null and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as t_t_falado,  
 (SELECT count(DISTINCT(callid))
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as abandonadas, 
 (SELECT max(tempo_fila)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as Maior, 
 (SELECT sum(tempo_fila)/count(DISTINCT(callid)) 
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as Medio, 
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as _20,  
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as m_20,
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:20' THEN 1 else 0 end ) 
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_20,   
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_m_20,  
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:30' THEN 1 else 0 end ) from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_30,
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:30' THEN 1 else 0 end)  from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as a_m_30,  
  (SELECT sum(case WHEN (tempo_fila) <= time '00:00:30' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as _30,  
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:30' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as m_30,
 (SELECT count(DISTINCT(callid))  from tb_billing 
 where grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Ativa' and (data_sistema + hora_sistema)  BETWEEN date ($1) + tb_interval_rel.intervalo and date ($1) + tb_interval_rel.intervalo + '00:30:00'
 ) as T_lig_out
  FROM tb_interval_rel,tb_virtual_groups order by tb_virtual_groups.virtual_group,tb_interval_rel.intervalo;
  RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_noturno_bil(text) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16471)
-- Name: rel_noturno_bil_sumario(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rel_noturno_bil_sumario(text, text) RETURNS TABLE(virtual_grp character varying, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior time without time zone, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
    LANGUAGE plpgsql ROWS 100000
    AS $_$
  BEGIN
 RETURN QUERY 
SELECT virtual_group,
 (SELECT count(callid)  from tb_billing 
 where grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_sistema = date ($1)   
 ) as T_lig, 
 (SELECT count(callid) from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null  and data_sistema = date ($1)    
 ) as atendidas, 
 (SELECT sum(tempo_chamada)/count(DISTINCT(callid))  from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is  null and data_sistema = date ($1)    
 ) as t_t_falado,  
 (SELECT count(DISTINCT(callid))
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and data_sistema = date ($1)    
 ) as abandonadas, 
 (SELECT max(tempo_fila)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and data_sistema = date ($1)    
 ) as Maior, 
 (SELECT sum(tempo_fila)/count(DISTINCT(callid)) 
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and data_sistema = date ($1)    
 ) as Medio, 
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  data_sistema = date ($1)    
 ) as _20,  
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  data_sistema = date ($1)    
 ) as m_20,
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:20' THEN 1 else 0 end ) 
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  data_sistema = date ($1)    
 ) as a_20,   
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:20' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  data_sistema = date ($1)    
 ) as a_m_20,  
 (SELECT sum(case WHEN (tempo_fila) <= time '00:00:30' THEN 1 else 0 end ) from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and  data_sistema = date ($1)    
 ) as a_30,
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:30' THEN 1 else 0 end)  from tb_billing 
 where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is null and data_sistema = date ($1)    
 ) as a_m_30,  
  (SELECT sum(case WHEN (tempo_fila) <= time '00:00:30' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  data_sistema = date ($1)    
 ) as _30,  
 (SELECT sum(case WHEN (tempo_fila) > time '00:00:30' THEN 1 else 0 end)  
 from tb_billing where  grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Receptiva' and data_abandono is not null and  data_sistema = date ($1)    
 ) as m_30,
 (SELECT count(DISTINCT(callid))  from tb_billing 
 where grupo = tb_virtual_groups.virtual_group and tipo_ligacao='Ativa' and data_sistema = date ($1)    
 ) as T_lig_out
  FROM tb_virtual_groups where tb_virtual_groups.virtual_group = $2 order by tb_virtual_groups.virtual_group;
  RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_noturno_bil_sumario(text, text) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 16472)
-- Name: rel_noturno_sumario(text, text); Type: FUNCTION; Schema: public; Owner: callproadmin
--

CREATE FUNCTION rel_noturno_sumario(text, text) RETURNS TABLE(virtual_grp character varying, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior interval, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
    LANGUAGE plpgsql ROWS 100000
    AS $_$
  BEGIN
 RETURN QUERY 
  SELECT virtual_group,
 (SELECT count(DISTINCT(channel))  from tb_chamadas 
 where acd_start is not NULL and tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59')  as T_lig, 
 (SELECT count(DISTINCT(channel)) from tb_chamadas
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  ) as atendidas,
  (SELECT sum(agente_end - agente_start)/count(DISTINCT(channel))  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  ) as t_t_falado,
 (SELECT count(uniqueid) from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN  date ($1) and  date ($1) + time '23:59:59'
 )as abandonadas,
 (SELECT max(date_end - acd_start)  from tb_chamadas 
 where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
 )as Maior,
  (SELECT sum(date_end - acd_start)/count(DISTINCT(channel))  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
 )as Medio,
 (SELECT sum(case WHEN (date_end - acd_start) < time '00:00:20' THEN 1 else 0 end)  from tb_chamadas 
    where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as _20,
  (SELECT sum(case WHEN (date_end - acd_start) > time '00:00:20' THEN 1 else 0 end)  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as m_20,
  (SELECT sum(case WHEN (agente_start - acd_start) < time '00:00:20' THEN 1 else 0 end ) from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as a_20,
  (SELECT sum(case WHEN (agente_start - acd_start) > time '00:00:20' THEN 1 else 0 end)  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as a_m_20,
  (SELECT sum(case WHEN (agente_start - acd_start) < time '00:00:30' THEN 1 else 0 end ) from tb_chamadas
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as a_30,
  (SELECT sum(case WHEN (agente_start - acd_start) > time '00:00:30' THEN 1 else 0 end)  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=true and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as a_m_30,
  (SELECT sum(case WHEN (date_end - acd_start) < time '00:00:30' THEN 1 else 0 end)  from tb_chamadas 
    where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as _30,
  (SELECT sum(case WHEN (date_end - acd_start) > time '00:00:30' THEN 1 else 0 end)  from tb_chamadas 
  where  tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='UV' and atendida=false and acd_start is not NULL and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59'
  )as m_30,
  (SELECT count(DISTINCT(channel))  from tb_chamadas 
 where tb_chamadas.virtual_group = tb_virtual_groups.virtual_group and modo='S' and date_end is not NULL and date_start BETWEEN date ($1)  and  date ($1) + time '23:59:59')  as T_lig
  FROM tb_virtual_groups where virtual_group = $2 order by tb_virtual_groups.virtual_group;
  RETURN;
  END;
$_$;


ALTER FUNCTION public.rel_noturno_sumario(text, text) OWNER TO callproadmin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 175 (class 1259 OID 16473)
-- Name: infos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE infos (
    tipo integer NOT NULL,
    valor character varying(64)
);


ALTER TABLE infos OWNER TO postgres;

--
-- TOC entry 176 (class 1259 OID 16476)
-- Name: login; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE login (
    "user" character varying(60) NOT NULL,
    pass character varying(60),
    tipo character varying(32),
    vrt_grp character varying(300)
);


ALTER TABLE login OWNER TO postgres;

--
-- TOC entry 177 (class 1259 OID 16479)
-- Name: logo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE logo (
    id integer NOT NULL,
    file bytea
);


ALTER TABLE logo OWNER TO postgres;

--
-- TOC entry 178 (class 1259 OID 16485)
-- Name: motivosdepausa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE motivosdepausa (
    id character varying(2) NOT NULL,
    decricao character varying(20),
    tempo time without time zone NOT NULL,
    produtiva boolean DEFAULT false NOT NULL,
    supervisionada boolean DEFAULT false NOT NULL
);


ALTER TABLE motivosdepausa OWNER TO postgres;

--
-- TOC entry 179 (class 1259 OID 16488)
-- Name: rec_middleware; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE rec_middleware (
    uniqueid character varying(30) NOT NULL,
    channel character varying(80),
    exten character varying(40),
    outgoing_call character varying(32),
    date_start timestamp without time zone,
    date_end timestamp with time zone,
    path character varying(300),
    record boolean DEFAULT false NOT NULL,
    conv boolean DEFAULT false NOT NULL,
    dur_file time without time zone,
    end_rec boolean DEFAULT false NOT NULL,
    serial integer NOT NULL
);


ALTER TABLE rec_middleware OWNER TO postgres;

--
-- TOC entry 180 (class 1259 OID 16494)
-- Name: rec_middleware_serial_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE rec_middleware_serial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rec_middleware_serial_seq OWNER TO postgres;

--
-- TOC entry 3305 (class 0 OID 0)
-- Dependencies: 180
-- Name: rec_middleware_serial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE rec_middleware_serial_seq OWNED BY rec_middleware.serial;


--
-- TOC entry 181 (class 1259 OID 16496)
-- Name: tb_ag_grupo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_ag_grupo (
    id integer NOT NULL,
    agente bigint,
    virtual_grp character varying(32),
    priority integer DEFAULT 0
);


ALTER TABLE tb_ag_grupo OWNER TO postgres;

--
-- TOC entry 182 (class 1259 OID 16500)
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_ag_grupo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_ag_grupo_id_seq OWNER TO postgres;

--
-- TOC entry 3306 (class 0 OID 0)
-- Dependencies: 182
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_ag_grupo_id_seq OWNED BY tb_ag_grupo.id;


--
-- TOC entry 183 (class 1259 OID 16502)
-- Name: tb_agente_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_agente_log (
    id bigint NOT NULL,
    agente bigint,
    extension character varying(40),
    data_ini timestamp with time zone,
    data_fim timestamp with time zone,
    tipo smallint,
    tp_pausa character varying(2)
);


ALTER TABLE tb_agente_log OWNER TO postgres;

--
-- TOC entry 184 (class 1259 OID 16505)
-- Name: tb_agente_log_detalhado; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_agente_log_detalhado (
    id bigint NOT NULL,
    fkiduser bigint,
    date timestamp without time zone,
    tp integer,
    id_intervalo character varying(2)
);


ALTER TABLE tb_agente_log_detalhado OWNER TO callproadmin;

--
-- TOC entry 185 (class 1259 OID 16508)
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE tb_agente_log_detalhado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_agente_log_detalhado_id_seq OWNER TO callproadmin;

--
-- TOC entry 3307 (class 0 OID 0)
-- Dependencies: 185
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE tb_agente_log_detalhado_id_seq OWNED BY tb_agente_log_detalhado.id;


--
-- TOC entry 186 (class 1259 OID 16510)
-- Name: tb_agente_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_agente_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_agente_log_id_seq OWNER TO postgres;

--
-- TOC entry 3308 (class 0 OID 0)
-- Dependencies: 186
-- Name: tb_agente_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_agente_log_id_seq OWNED BY tb_agente_log.id;


--
-- TOC entry 187 (class 1259 OID 16512)
-- Name: tb_agente_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_agente_status (
    id bigint NOT NULL,
    status integer DEFAULT 0,
    channel character varying(30),
    tecnologia character varying(10),
    tp_de_pausa character varying(2),
    date_status timestamp without time zone,
    dialer boolean DEFAULT false NOT NULL,
    "TAB_wait" boolean DEFAULT false NOT NULL,
    "DIALER_CAMPANHA" character varying(100),
    "DIALER_CLIENTE" character varying(200),
    "DIALER_CAMPOS" character varying(1000),
    "DIALER_VALORES" character varying(1000),
    "DIALER_STATUS" integer
);


ALTER TABLE tb_agente_status OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 16521)
-- Name: tb_agentes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_agentes (
    id bigint NOT NULL,
    n_agente character varying(100),
    nickname character varying(30),
    ativo boolean DEFAULT false NOT NULL,
    historico boolean DEFAULT false NOT NULL,
    historico_recs boolean DEFAULT false NOT NULL,
    notgrp character varying(32) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE tb_agentes OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 16525)
-- Name: tb_ani; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_ani (
    nome character varying(64) NOT NULL,
    ativo boolean
);


ALTER TABLE tb_ani OWNER TO callproadmin;

--
-- TOC entry 190 (class 1259 OID 16528)
-- Name: tb_ani_route; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_ani_route (
    serial integer NOT NULL,
    numero character varying(32) NOT NULL,
    nome character varying(32),
    priority integer NOT NULL,
    r_route boolean NOT NULL,
    dest_r_route character varying(40) NOT NULL,
    ani character varying(32) NOT NULL,
    ani_name integer DEFAULT 0 NOT NULL
);


ALTER TABLE tb_ani_route OWNER TO callproadmin;

--
-- TOC entry 191 (class 1259 OID 16532)
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE tb_ani_route_serial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_ani_route_serial_seq OWNER TO callproadmin;

--
-- TOC entry 3309 (class 0 OID 0)
-- Dependencies: 191
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE tb_ani_route_serial_seq OWNED BY tb_ani_route.serial;


--
-- TOC entry 192 (class 1259 OID 16534)
-- Name: tb_anuncios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_anuncios (
    anuncio character varying(150) NOT NULL
);


ALTER TABLE tb_anuncios OWNER TO postgres;

--
-- TOC entry 193 (class 1259 OID 16537)
-- Name: tb_billing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_billing (
    id integer NOT NULL,
    tipo_ligacao character varying(60),
    callid character varying(60),
    ani bigint,
    dnis bigint,
    data_sistema date,
    hora_sistema time without time zone,
    grupo_atendimentoinicial character varying(60),
    atendente_atendimentoinicial character varying(60),
    data_atendimentoinicial date,
    hora_atendimentoinicial time without time zone,
    grupo character varying(60),
    data_pa date,
    hora_pa time without time zone,
    data_abandono date,
    hora_abandono time without time zone,
    responsavel_abandono character varying(60),
    data_desligada date,
    hora_desligada time without time zone,
    atendente character varying(60),
    tempo_chamada time without time zone,
    tempo_fila time without time zone,
    local_abandono character varying(60),
    resultado_transferencia character varying(100),
    resultado_atendente character varying(100),
    tipo_transferenciaexterna character varying(60),
    numero_transferenciaexterna character varying(60),
    coletado boolean
);


ALTER TABLE tb_billing OWNER TO postgres;

--
-- TOC entry 194 (class 1259 OID 16543)
-- Name: tb_billing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_billing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_billing_id_seq OWNER TO postgres;

--
-- TOC entry 3310 (class 0 OID 0)
-- Dependencies: 194
-- Name: tb_billing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_billing_id_seq OWNED BY tb_billing.id;


--
-- TOC entry 195 (class 1259 OID 16545)
-- Name: tb_camp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_camp (
    id integer NOT NULL,
    nom_camp character varying(64),
    data_ini timestamp without time zone NOT NULL,
    data_end timestamp without time zone NOT NULL,
    quota integer NOT NULL,
    paral_disc integer,
    parl_disc_ag integer DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT false NOT NULL
);


ALTER TABLE tb_camp OWNER TO postgres;

--
-- TOC entry 196 (class 1259 OID 16550)
-- Name: tb_camp_10000; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_camp_10000 (
    tel character varying(20) NOT NULL,
    contato character varying(64),
    status integer DEFAULT 0 NOT NULL,
    data_agendamento timestamp without time zone NOT NULL,
    data_last timestamp without time zone NOT NULL,
    n_tentativas integer DEFAULT 0 NOT NULL,
    abortado integer DEFAULT 0 NOT NULL,
    campos character varying(1000),
    valores character varying(1000),
    obs character varying(1000)
);


ALTER TABLE tb_camp_10000 OWNER TO callproadmin;

--
-- TOC entry 197 (class 1259 OID 16559)
-- Name: tb_camp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_camp_id_seq
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    MAXVALUE 99999
    CACHE 1;


ALTER TABLE tb_camp_id_seq OWNER TO postgres;

--
-- TOC entry 3311 (class 0 OID 0)
-- Dependencies: 197
-- Name: tb_camp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_camp_id_seq OWNED BY tb_camp.id;


--
-- TOC entry 230 (class 1259 OID 16836)
-- Name: tb_chamadas; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE tb_chamadas (
    uniqueid character varying(36) NOT NULL,
    channel character varying(80),
    ani character varying(32),
    agente bigint,
    extension character varying(40),
    dnis character varying(32),
    virtual_group character varying(32),
    outgoing_call character varying(32),
    date_start timestamp without time zone,
    acd_start timestamp without time zone,
    agente_start timestamp without time zone,
    agente_end timestamp without time zone,
    date_end timestamp without time zone,
    dialinidate timestamp without time zone,
    modo character varying(3),
    atendida boolean NOT NULL,
    record boolean DEFAULT false NOT NULL,
    a_agente boolean DEFAULT false NOT NULL,
    v_score character varying(1) DEFAULT 'N'::character varying,
    conv boolean DEFAULT false NOT NULL,
    dur_file time without time zone,
    tab_1 character varying(32),
    tab_2 character varying(32),
    h_agente boolean DEFAULT false NOT NULL,
    d_uniqueid character varying(30),
    dialstatus character varying(20),
    custom_vars text,
    cdr boolean DEFAULT false NOT NULL,
    date_end_tab timestamp without time zone,
    dest_channel character varying(32),
    real_dial_number character varying(32),
    cdr_tipo character varying(10)
);


ALTER TABLE tb_chamadas OWNER TO gravador;

--
-- TOC entry 198 (class 1259 OID 16569)
-- Name: tb_codigos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_codigos (
    codigo character varying(8) NOT NULL,
    facilidade character varying(20)
);


ALTER TABLE tb_codigos OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 16572)
-- Name: tb_dialer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_dialer (
    id integer NOT NULL,
    n_disc character varying(32) NOT NULL,
    info1 character varying(128),
    status smallint DEFAULT 0,
    ramal character varying(6),
    agente integer,
    data timestamp without time zone,
    camp integer
);


ALTER TABLE tb_dialer OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 16576)
-- Name: tb_dialer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_dialer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_dialer_id_seq OWNER TO postgres;

--
-- TOC entry 3312 (class 0 OID 0)
-- Dependencies: 200
-- Name: tb_dialer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_dialer_id_seq OWNED BY tb_dialer.id;


--
-- TOC entry 225 (class 1259 OID 16794)
-- Name: tb_dialercallback; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE tb_dialercallback (
    camp_id integer NOT NULL,
    camp_name character varying NOT NULL,
    ativo boolean DEFAULT false NOT NULL,
    virtualgroup character varying NOT NULL,
    digits_map character varying,
    digits_timeout integer DEFAULT 5000 NOT NULL,
    playback character varying,
    qmaxfila integer DEFAULT 1 NOT NULL,
    qdisc_p_agent integer DEFAULT 3 NOT NULL,
    qdisc_simult integer DEFAULT 30 NOT NULL,
    q_preload bigint DEFAULT 200 NOT NULL
);


ALTER TABLE tb_dialercallback OWNER TO gravador;

--
-- TOC entry 224 (class 1259 OID 16792)
-- Name: tb_dialercallback_camp_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE tb_dialercallback_camp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_dialercallback_camp_id_seq OWNER TO gravador;

--
-- TOC entry 3313 (class 0 OID 0)
-- Dependencies: 224
-- Name: tb_dialercallback_camp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE tb_dialercallback_camp_id_seq OWNED BY tb_dialercallback.camp_id;


--
-- TOC entry 227 (class 1259 OID 16811)
-- Name: tb_dialercallback_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_dialercallback_log (
    id bigint NOT NULL,
    id_tb_num character varying(20),
    id_cliente character varying(20),
    tel character varying(20) NOT NULL,
    data_discagem timestamp without time zone DEFAULT now() NOT NULL,
    data_hangup timestamp without time zone,
    data_agi timestamp without time zone,
    data_rfila timestamp without time zone,
    status integer,
    uniqueid character varying(36),
    digit character varying(4),
    dest character varying(8),
    coletado boolean DEFAULT false NOT NULL
);


ALTER TABLE tb_dialercallback_log OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16809)
-- Name: tb_dialercallback_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_dialercallback_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_dialercallback_log_id_seq OWNER TO postgres;

--
-- TOC entry 3314 (class 0 OID 0)
-- Dependencies: 226
-- Name: tb_dialercallback_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_dialercallback_log_id_seq OWNED BY tb_dialercallback_log.id;


--
-- TOC entry 229 (class 1259 OID 16821)
-- Name: tb_dialercallback_num; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE tb_dialercallback_num (
    id bigint NOT NULL,
    id_cliente character varying(20),
    tel character varying(20) NOT NULL,
    contato character varying(64),
    campos character varying(1000),
    valores character varying(1000),
    obs character varying(1000),
    status integer DEFAULT 0 NOT NULL,
    pausado boolean DEFAULT false NOT NULL,
    camp_id integer NOT NULL,
    playback_custom character varying(30),
    data_agendamento timestamp without time zone DEFAULT '2001-01-01 00:00:00'::timestamp without time zone NOT NULL,
    data_last timestamp without time zone DEFAULT now() NOT NULL,
    n_tentativas integer DEFAULT 0 NOT NULL,
    abortado integer DEFAULT 0 NOT NULL
);


ALTER TABLE tb_dialercallback_num OWNER TO gravador;

--
-- TOC entry 228 (class 1259 OID 16819)
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE tb_dialercallback_num_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_dialercallback_num_id_seq OWNER TO gravador;

--
-- TOC entry 3315 (class 0 OID 0)
-- Dependencies: 228
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE tb_dialercallback_num_id_seq OWNED BY tb_dialercallback_num.id;


--
-- TOC entry 201 (class 1259 OID 16578)
-- Name: tb_dnis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_dnis (
    dnis character varying(8) NOT NULL,
    obs character varying(200),
    time_condition character varying(32)
);


ALTER TABLE tb_dnis OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16581)
-- Name: tb_dt_chamadas; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_dt_chamadas (
    uniqueid character varying(20) NOT NULL,
    channel character varying(80),
    ani_name character varying(32),
    ani_num character varying(32),
    last_date timestamp without time zone,
    actionid_response character varying(80),
    virtual_group character varying(32),
    t_timeout character varying(64),
    d_timeout character varying(64),
    t_wait_agente character varying(64),
    r_agente_time character varying(64),
    script character varying,
    queue character varying(64),
    sendaction character varying(64),
    t_score integer,
    o_serv timestamp with time zone,
    priority integer,
    r_ani_name integer,
    tab character varying(1010)
);


ALTER TABLE tb_dt_chamadas OWNER TO callproadmin;

--
-- TOC entry 203 (class 1259 OID 16587)
-- Name: tb_facilidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_facilidades (
    facilidade character varying(30),
    recurso character varying(30) NOT NULL,
    tipo integer
);


ALTER TABLE tb_facilidades OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16925)
-- Name: tb_internalchat; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_internalchat (
    id bigint NOT NULL,
    date_send timestamp without time zone DEFAULT now() NOT NULL,
    dst bigint NOT NULL,
    src bigint NOT NULL,
    msg text,
    read smallint DEFAULT 0 NOT NULL
);


ALTER TABLE tb_internalchat OWNER TO callproadmin;

--
-- TOC entry 231 (class 1259 OID 16923)
-- Name: tb_internalchat_id_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE tb_internalchat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_internalchat_id_seq OWNER TO callproadmin;

--
-- TOC entry 3316 (class 0 OID 0)
-- Dependencies: 231
-- Name: tb_internalchat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE tb_internalchat_id_seq OWNED BY tb_internalchat.id;


--
-- TOC entry 204 (class 1259 OID 16590)
-- Name: tb_interval_rel; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_interval_rel (
    intervalo time without time zone NOT NULL
);


ALTER TABLE tb_interval_rel OWNER TO callproadmin;

--
-- TOC entry 205 (class 1259 OID 16593)
-- Name: tb_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_log (
    usuario character varying(500),
    data timestamp without time zone DEFAULT now() NOT NULL,
    tipo integer DEFAULT 0,
    evento character varying(30000)
);


ALTER TABLE tb_log OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16601)
-- Name: tb_musiconhold; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_musiconhold (
    classe character varying(50) NOT NULL,
    _mode character varying(10),
    directory character varying(200),
    sort character varying(10)
);


ALTER TABLE tb_musiconhold OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16604)
-- Name: tb_queues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_queues (
    name character varying(32) NOT NULL,
    script character varying(500) NOT NULL
);


ALTER TABLE tb_queues OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16610)
-- Name: tb_ramais; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_ramais (
    id integer NOT NULL,
    tecnologia character varying(50),
    ramal character varying(40),
    softphone integer DEFAULT 0 NOT NULL,
    softphone_video integer DEFAULT 0 NOT NULL
);


ALTER TABLE tb_ramais OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16613)
-- Name: tb_ramais_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tb_ramais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_ramais_id_seq OWNER TO postgres;

--
-- TOC entry 3317 (class 0 OID 0)
-- Dependencies: 209
-- Name: tb_ramais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tb_ramais_id_seq OWNED BY tb_ramais.id;


--
-- TOC entry 217 (class 1259 OID 16640)
-- Name: tb_rel_ani; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_rel_ani (
    num character varying(32) NOT NULL,
    text character varying(64),
    grupo character varying(32)
);


ALTER TABLE tb_rel_ani OWNER TO callproadmin;

--
-- TOC entry 210 (class 1259 OID 16615)
-- Name: tb_rel_virtual_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_rel_virtual_group (
    grupo character varying(60) NOT NULL
);


ALTER TABLE tb_rel_virtual_group OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16618)
-- Name: tb_sms_conf_alerta; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_sms_conf_alerta (
    numero character varying(6) NOT NULL,
    string character varying(160),
    sms_s character varying(300)
);


ALTER TABLE tb_sms_conf_alerta OWNER TO callproadmin;

--
-- TOC entry 212 (class 1259 OID 16621)
-- Name: tb_sms_received; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_sms_received (
    id integer NOT NULL,
    sender character varying(16),
    sent timestamp without time zone,
    status character varying(20),
    message character varying(200),
    read boolean DEFAULT false NOT NULL,
    resend character varying(40)
);


ALTER TABLE tb_sms_received OWNER TO callproadmin;

--
-- TOC entry 213 (class 1259 OID 16625)
-- Name: tb_sms_received_id_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE tb_sms_received_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_sms_received_id_seq OWNER TO callproadmin;

--
-- TOC entry 3318 (class 0 OID 0)
-- Dependencies: 213
-- Name: tb_sms_received_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE tb_sms_received_id_seq OWNED BY tb_sms_received.id;


--
-- TOC entry 214 (class 1259 OID 16627)
-- Name: tb_sms_send; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_sms_send (
    id integer NOT NULL,
    id_tipo integer,
    desc_tipo character varying(100),
    num_sms character varying(16),
    texto character varying(160),
    status integer,
    data timestamp with time zone DEFAULT now() NOT NULL,
    "user" character varying(50) DEFAULT 'SERVIDOR'::character varying NOT NULL
);


ALTER TABLE tb_sms_send OWNER TO callproadmin;

--
-- TOC entry 215 (class 1259 OID 16632)
-- Name: tb_sms_send_id_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE tb_sms_send_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tb_sms_send_id_seq OWNER TO callproadmin;

--
-- TOC entry 3319 (class 0 OID 0)
-- Dependencies: 215
-- Name: tb_sms_send_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE tb_sms_send_id_seq OWNED BY tb_sms_send.id;


--
-- TOC entry 216 (class 1259 OID 16634)
-- Name: tb_tabs; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_tabs (
    tab character varying(32) NOT NULL,
    valores character varying(1000) NOT NULL
);


ALTER TABLE tb_tabs OWNER TO callproadmin;

--
-- TOC entry 219 (class 1259 OID 16649)
-- Name: tb_time_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_time_conditions (
    name character varying(32) NOT NULL,
    script character varying
)
WITH (autovacuum_enabled='true');


ALTER TABLE tb_time_conditions OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16655)
-- Name: tb_trunks; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tb_trunks (
    tronco character varying(60) NOT NULL,
    aliases character varying(60),
    tipo character varying(10)
);


ALTER TABLE tb_trunks OWNER TO callproadmin;

--
-- TOC entry 218 (class 1259 OID 16643)
-- Name: tb_uf; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_uf (
    num character varying(32) NOT NULL,
    text character varying(64)
);


ALTER TABLE tb_uf OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16658)
-- Name: tb_virtual_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tb_virtual_groups (
    virtual_group character varying(32) NOT NULL,
    queue character varying(32),
    t_timeout integer DEFAULT 3600,
    d_timeout character varying(100),
    t_wait_agente integer DEFAULT 15,
    r_agente_time integer DEFAULT 0,
    dest_tranb character varying(50),
    t_scoring integer DEFAULT 0,
    o_serv time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    o_fila time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    tab character varying(32) DEFAULT '###SEM TAB###'::character varying NOT NULL,
    t_tab integer DEFAULT 0 NOT NULL,
    priority integer DEFAULT 0 NOT NULL
);


ALTER TABLE tb_virtual_groups OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16670)
-- Name: tbl; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE tbl (
    id integer,
    ts time without time zone
);


ALTER TABLE tbl OWNER TO callproadmin;

--
-- TOC entry 223 (class 1259 OID 16673)
-- Name: td_dias_esp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE td_dias_esp (
    date timestamp with time zone NOT NULL,
    "Name" character varying(32)
);


ALTER TABLE td_dias_esp OWNER TO postgres;

--
-- TOC entry 2979 (class 2604 OID 16676)
-- Name: serial; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rec_middleware ALTER COLUMN serial SET DEFAULT nextval('rec_middleware_serial_seq'::regclass);


--
-- TOC entry 2981 (class 2604 OID 16677)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ag_grupo ALTER COLUMN id SET DEFAULT nextval('tb_ag_grupo_id_seq'::regclass);


--
-- TOC entry 2982 (class 2604 OID 16860)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_agente_log ALTER COLUMN id SET DEFAULT nextval('tb_agente_log_id_seq'::regclass);


--
-- TOC entry 2983 (class 2604 OID 16871)
-- Name: id; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_agente_log_detalhado ALTER COLUMN id SET DEFAULT nextval('tb_agente_log_detalhado_id_seq'::regclass);


--
-- TOC entry 2992 (class 2604 OID 16680)
-- Name: serial; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_ani_route ALTER COLUMN serial SET DEFAULT nextval('tb_ani_route_serial_seq'::regclass);


--
-- TOC entry 2993 (class 2604 OID 16681)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_billing ALTER COLUMN id SET DEFAULT nextval('tb_billing_id_seq'::regclass);


--
-- TOC entry 2996 (class 2604 OID 16682)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_camp ALTER COLUMN id SET DEFAULT nextval('tb_camp_id_seq'::regclass);


--
-- TOC entry 3001 (class 2604 OID 16683)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_dialer ALTER COLUMN id SET DEFAULT nextval('tb_dialer_id_seq'::regclass);


--
-- TOC entry 3021 (class 2604 OID 16797)
-- Name: camp_id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY tb_dialercallback ALTER COLUMN camp_id SET DEFAULT nextval('tb_dialercallback_camp_id_seq'::regclass);


--
-- TOC entry 3028 (class 2604 OID 16814)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_dialercallback_log ALTER COLUMN id SET DEFAULT nextval('tb_dialercallback_log_id_seq'::regclass);


--
-- TOC entry 3031 (class 2604 OID 16824)
-- Name: id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY tb_dialercallback_num ALTER COLUMN id SET DEFAULT nextval('tb_dialercallback_num_id_seq'::regclass);


--
-- TOC entry 3044 (class 2604 OID 16928)
-- Name: id; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_internalchat ALTER COLUMN id SET DEFAULT nextval('tb_internalchat_id_seq'::regclass);


--
-- TOC entry 3004 (class 2604 OID 16684)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ramais ALTER COLUMN id SET DEFAULT nextval('tb_ramais_id_seq'::regclass);


--
-- TOC entry 3008 (class 2604 OID 16685)
-- Name: id; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_sms_received ALTER COLUMN id SET DEFAULT nextval('tb_sms_received_id_seq'::regclass);


--
-- TOC entry 3011 (class 2604 OID 16686)
-- Name: id; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_sms_send ALTER COLUMN id SET DEFAULT nextval('tb_sms_send_id_seq'::regclass);


--
-- TOC entry 3239 (class 0 OID 16473)
-- Dependencies: 175
-- Data for Name: infos; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO infos VALUES (10, '5#5#10#10#30#60');
INSERT INTO infos VALUES (3, '5');
INSERT INTO infos VALUES (1, 'CALLROUTE');
INSERT INTO infos VALUES (2, '1');


--
-- TOC entry 3240 (class 0 OID 16476)
-- Dependencies: 176
-- Data for Name: login; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO login VALUES ('ADMIN', '31994', 'ADMINISTRADOR', 'TODOS');


--
-- TOC entry 3241 (class 0 OID 16479)
-- Dependencies: 177
-- Data for Name: logo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO logo VALUES (0, '\x5c3337375c3333305c3337375c3334305c3030305c3032304a4649465c3030305c3030315c3030315c3030315c3030305c3331305c3030305c3331305c3030305c3030305c3337375c3333335c303030435c3030305c3030335c3030325c3030325c3030335c3030325c3030325c3030335c3030335c3030335c3030335c3030345c3030335c3030335c3030345c3030355c3031305c3030355c3030355c3030345c3030345c3030355c3031325c3030375c3030375c3030365c3031305c3031345c3031325c3031345c3031345c3031335c3031325c3031335c3031335c3031355c3031365c3032325c3032305c3031355c3031365c3032315c3031365c3031335c3031335c3032305c3032365c3032305c3032315c3032335c3032345c3032355c3032355c3032355c3031345c3031375c3032375c3033305c3032365c3032345c3033305c3032325c3032345c3032355c3032345c3337375c3333335c303030435c3030315c3030335c3030345c3030345c3030355c3030345c3030355c3031315c3030355c3030355c3031315c3032345c3031355c3031335c3031355c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3032345c3337375c3330305c3030305c3032315c3031305c3030305c3331325c3030335c3233365c3030335c303031225c3030305c3030325c3032315c3030315c3030335c3032315c3030315c3337375c3330345c3030305c3033375c3030305c3030305c3030315c3030355c3030315c3030315c3030315c3030315c3030315c3030315c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030315c3030325c3030335c3030345c3030355c3030365c3030375c3031305c3031315c3031325c3031335c3337375c3330345c3030305c3236355c3032305c3030305c3030325c3030315c3030335c3030335c3030325c3030345c3030335c3030355c3030355c3030345c3030345c3030305c3030305c3030317d5c3030315c3030325c3030335c3030305c3030345c3032315c3030355c3032322131415c3030365c30323351615c30303722715c303234325c3230315c3232315c3234315c30313023425c3236315c3330315c303235525c3332315c333630243362725c3230325c3031315c3031325c3032365c3032375c3033305c3033315c30333225262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a5c3230335c3230345c3230355c3230365c3230375c3231305c3231315c3231325c3232325c3232335c3232345c3232355c3232365c3232375c3233305c3233315c3233325c3234325c3234335c3234345c3234355c3234365c3234375c3235305c3235315c3235325c3236325c3236335c3236345c3236355c3236365c3236375c3237305c3237315c3237325c3330325c3330335c3330345c3330355c3330365c3330375c3331305c3331315c3331325c3332325c3332335c3332345c3332355c3332365c3332375c3333305c3333315c3333325c3334315c3334325c3334335c3334345c3334355c3334365c3334375c3335305c3335315c3335325c3336315c3336325c3336335c3336345c3336355c3336365c3336375c3337305c3337315c3337325c3337375c3330345c3030305c3033375c3030315c3030305c3030335c3030315c3030315c3030315c3030315c3030315c3030315c3030315c3030315c3030315c3030305c3030305c3030305c3030305c3030305c3030305c3030315c3030325c3030335c3030345c3030355c3030365c3030375c3031305c3031315c3031325c3031335c3337375c3330345c3030305c3236355c3032315c3030305c3030325c3030315c3030325c3030345c3030345c3030335c3030345c3030375c3030355c3030345c3030345c3030305c3030315c303032775c3030305c3030315c3030325c3030335c3032315c3030345c30303521315c3030365c30323241515c30303761715c30323322325c3230315c3031305c303234425c3232315c3234315c3236315c3330315c3031312333525c3336305c30323562725c3332315c3031325c30323624345c333431255c3336315c3032375c3033305c3033315c303332262728292a35363738393a434445464748494a535455565758595a636465666768696a737475767778797a5c3230325c3230335c3230345c3230355c3230365c3230375c3231305c3231315c3231325c3232325c3232335c3232345c3232355c3232365c3232375c3233305c3233315c3233325c3234325c3234335c3234345c3234355c3234365c3234375c3235305c3235315c3235325c3236325c3236335c3236345c3236355c3236365c3236375c3237305c3237315c3237325c3330325c3330335c3330345c3330355c3330365c3330375c3331305c3331315c3331325c3332325c3332335c3332345c3332355c3332365c3332375c3333305c3333315c3333325c3334325c3334335c3334345c3334355c3334365c3334375c3335305c3335315c3335325c3336325c3336335c3336345c3336355c3336365c3336375c3337305c3337315c3337325c3337375c3333325c3030305c3031345c3030335c3030315c3030305c3030325c3032315c3030335c3032315c3030303f5c3030305c333735535c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030322b5c3233335c3233305c3335352169656d5c3232315c3235375c33333662385c3030335c3332345c3337325c303137535c3332305c3031364d7c5c3330315c3336314f5c3336365c3330365c3337335c3031375c3231305c3234375c3336305c3335375c3230305c3236345c3237315c3237344b5c3235325c323536635c3333375c3030325c3232335c303232303f312763645c3231374e5c3030365c303033645c3230335c333637205c3337355c3235367e266b775c333336205c3332333e5c303237786a615c3032355c3336365c3235365c3032355c323537254d5c3337375c3030305c3237325c3230305c3336352c425c3336315c3330364f5c3033355c3232345c333637395f5c5c5c333730255c33363033405c333730415c3334315c3331305c323535745c333733645c3232365c33353655565c3237315c3237355c323332355c3336335c3235365b5c333435605c3331375c3232345c3030345c303235235c3230315c3330376e5c3030375c303031795c3333345c323437295c3336325c333037445c3236375c3137375c333434785c303235715c3033305c3233346579615c3336305c32313546305c333232535c3333355c3333377b456d755c3332355c3237355c3032365c3332365c3237365c3333365c3030375c3033343f5c3236345c3237375c3231315c3233312f5c3334335c3236315c3236315c3332323c5c3330363b525c3335335c303032405c3234345c3235372e365c323334305c3330325c323230405c3033305c3334335c30333342623a5c3232325c333734475c3337305c3336355c3336305c3232315c3032326f5c30323078695c3236354d2e3c315c3233374f5c3033346c5c303132725f5c30313079555c3334345c3030325c3030305c3330305c3330315c3330365c3332315c3334355c333732675c3231333f6c7b2f5c3031375c3337305c333237555c3336305c3333355c3231375c3230325c3236355c333335725c3335334f5c3233335c3331315c3232324b485c3336325c3031375c3033315c3335315c323032415c3330306c5c3030335c323032765c323337435c3231345c3331335c3231375c3333336f4f5c3236335c3333305c3337325c3334375c3330335c3237375c3032335c3335315c3232365c3030355c3232355c3237365c333231716b5c3330325c333634205c3232305c333031406c5c323032405c3331367e5f635c32313677285c3235355c3235323d3f5c3235365c3330375c3231345c3335325c33343123775c30313475445c3332355c3336357a5c3235335c3235355c3335365c323334796d5c333337635c3237335c333730395c333733495c3337307b5c3334325c3235355c3231344b5c3030334b5c3030355c333632645c5c4332307870325c3031335c3337345c3234305c3030315c3231345c3334355c3237305c303334675c3030335c3031345c3032335c3333305c3235335c3334325c3237375c3231355c3033375c3031355c3236345c3333335c3233355c3031325c3332335c3334333f5c3330325c3236305c3234355c3234305c3030365c3335365c333636216d5c3236362b5c3235305c3232345c323031245c3331345c323431315c32373075235c333435235c3031355c3332305c3234375c3331315c333634375c3335345c3337355c3336315c3033365c3031375c3231305c3337375c3030305c3031375c3236345c33333542375c3233355c3334345c3232365c303337315c3230345c3235315c3231372f5c3334362a535c323035505c303130653c635c3234374c605c3235325c3336345c3332335c3233345c323333715c3232365c3337375c3030305c3233323d5c3333345c303036365c323435595c32373436265c3333345c33353173265c3236365c3232345e5c3332325d5c323733355c333637685c3331374e5c3234325c3231322b735c3333335c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132695c3232305c3031315c303235395c3331315c3030345c333437695c3330375c3033305c3335375c333230755c3335315c3336355c333634355a5c333437515c3231365c3333365c33333525205c323035605c3033345c3233315c3032355c3232342a5c3334345c3030325b5c3231375c3232375c3030305c3334375c3030375c3033355c303136705c303031235c3231335c3332353c586c5c3334315c3232305c3334305c3231315c303031576f3a20555c3334345c3030306d5c3331315c3032315c32313677445c3333365c3334335c3234375c333132735c333435203b465c33323520485c3331345c3231375c333436465c3230306e2c5c3336305c3237325c3230355c3033372f245c3232315c3330375c3333365c3033315c3331374c367e5c3335315c3330345c3032326b5c3336365c3231325c3237372c5c323433235c3030355c3230345c3231325c3331315c32363572324f5c303334606e5c3335335c3337355c3330365c333136365c3236315c30333629735c3334335c3232305c3236315c3236315c323136595c3335355c3336305c3030335c3334355c3332335c30303234275c3230325c31373776365c3334305c3032345c3334375c32313479595c333433605c3333315c323331755c3334335c33323579665c333333222c725c3236305c3231375c3031365c3230305c3032355c3231335c3337355c3236335c323630636f5c333134315c3231363c5c3237375c3334315c3336325c3331365c333030765c3335367b5c3335335c3337305c3230325c3331342e52515c323230465c3335355c3335325c3331325c30323464645c323336385c3330305c3333355c3332375c3337335c3231355c3233346d6c5c3031375c3334325c303133305c3237314946415c3033335c3236375c32353328515c3232315c323232785c3334335c303033775f5c33353636715c3236355c3236315c3334305c303233785c3336332640655c3231305c3231315c3031305c3231315c323133465c3032375c3032315c3334335c3233355c3333314e365c3337345c3333305c3033355c3237345c3237375c3334315c3336325c3331365c3330326f5c303336645c3331305c3031345c3236315c303231215c30323131685c3330325c3334323c735c323733295c3330365c3333375c3233335c3030335c3236375c3232375c3337343e595c3333305c3030315c3335375c3335375c3334325c303133305c3237314946415c3033335c3236375c32353328515c3232315c323232785c3334335c303033775f5c33353636715c3236355c3236303f5c3231302c5c3330325c333435255c3033315c3030346e5c3333365c3235345c3234314646495c3334335c3231345c3031355c3333355c3137375c3237305c3333315c3330365c3332365c3330375c3230304d5c3334335c3331345c3233315c3030315c323236222422262d5c3033305c5c475c3231367765385c3333335c33363360765c3336325c3337375c3030305c3230375c3331333b5c3031315c323734795c32323320325c333034445c323034445c3330355c3234335c3031335c3231305c3336315c3331365c3335345c3234375c3033337e6c5c3031365c3333365f5c3336305c33373167605c3030375c3237375c3237375c3231302c5c3330325c333435255c3033315c3030346e5c3333365c3235345c3234314646495c3334335c3231345c3031355c3333355c3137375c3237305c3333315c3330365c3332365c3330345c3332306b5c3032365c3236372c562777615c3231345c3230315c30323364645c3230315c3331375c30333472715c333137425c3235355c3337355c3332365c3330375c33313753785c3336332640655c3231305c3231315c3031305c3231315c323133465c3032375c3032315c3334335c3233355c3333314e365c3337345c3333305c3033355c3237345c3237375c3334315c3336325c3331365c3331355c3233355c3033375c3330365c3233376a5c323333685c3233355c3233345c3234302c5c3030365c3330335c3033325c3231345c3030335c3336325c32333426415c3333355c3236305c3031345c3032315c3230335c30333638315c3230325c3230305c3033365c3335315c3033355c3330324b5c32363368715c323735775c3231355c3331305c3330335c3231363a5c33343470795c333530795c3335335c3335306a5a5c333433342b5c32373124225c33333523765c3230344a5c3234355c3232375c3331325c3330365c3332325c3236322a5c333536205c32343670366070315c323136365c323030443d7d5c3237315c3333356f5c3032315c3333345c3335375c3232355c303337345c3231335c3236355c3231375c303335485c3330305c3330315c3336365c3330305c333732535c303231255c30323451405c3030355c303234565c3030365c3235335c323537345c3031363c5c3236325c3331315c3230315c3232305c3031305c333332715c323035605c3331345c30333546385c3031363a5c3231365c3231355c323232305c3331355c3033305c3030365c3330355c3331355c333434566b5c32373252515c3030305c3333345f692a5c32343320645c323230303a5c3336375c3335355c3232335c3332305c303334664d5c33343268635c323235425c333534685c333133605c3236333329415c3330364b5c3030325c323734635c3334375c3033305c333534505c3334375c303030394f375c333631475c323135235c3236335c3233355c323230345c3332315c3335345c3333345c3336324c415c3333345c3235375c3330325c32363176315c3231345c3030305c3330315c303330745c3330305c5c5c3337345c323733405c3231375c3230355c3332355c333734785c3230365c33363448235c3032325c3234335c3032365c3231355c3030315c5c32265c3333345c3337345c333331405c3234335c3030335c333134504e365c3233305c3330305c333731425c3236365c3330345c3030375c3237345c3330315c333432603e5c3331375c3334365c32333463315c3331315c3237355c3236315c3231346d5c3331335c3236375c333130315c333637645c3335315c3231375c323732725c3030365c3033375c3331335c3332325c3236325c3332355c3234305c323333315c3231315c303336664d5c323433775c3232365c3330355c3231305c333430655c323030505c3032345c333536245c3032315c3332335c3334356e5c323333582f5c333134565e335c3336325c3334365c3236375c3031365c3231365c3234305c3335365c3230315c333336655c333731735c3332315c3233355c3230315c323134635c303333245c3330315c3330305c303337425c3033335c3331335c333535745c3031375c3033335c3230365c32373145495c3331345c3235375c3031305c3336335c30323564425c3032346d5c3030375c3031325c333033613f78205c333532395c3231375c3033345c3032345c3331325c3030307b5c323734725c30313163575c5c5c323035605c3031305c3333345c3234354f5c3334325c303137235c333530695c3332355c333135683a5c323330755c3030325c3032342a5c3030315c3333305c3336315c3032342a465c303134715c33353620443f5c3237325c3337305c3331363a5c3033365c323330223e5c323136395c3030345c3236315c3235335c323536425c3236305c3030346e525c3234375c3336315c3030375c3232315c333634345c333030755c30323451405c3030355c30323451405c3030355c30323451405c3030355c303234554b5c3231354a38205948605c3234345c3030362644655c3031325c3237315c3030305c323236385c333731705c30313670715c3332305c3334375c3030305c3032325c3030302d5c33323569755c303130605c323035655c3232305c323732465c3331335c32373773465c333030285c3334335c3232365c3334335c3334355c3335335c3333375c3033305c3030305c3233365c3230305c3334335c3231375c3332357c5e6d2d5c3033375c3331345c3336335c303332455c303132575c33313650505c3331303057385c3231345c3137375c3032346f5c33353072715c3336325c3232307c5c3235365c303237535c3336315c3232375c3333315c3234305d5c323135255c323736325c3334365c5c64225c3334375c30333024285c3031335c3231375c3232305c323032315c3231355c3233315c3335305c323132235c303037635c333237255c333631255c3237344c5c303036472e5c3030365b725c3335354c645c32363365785c3330375c333134315c3331375c3333356c5c3334336b5c3335355c3234315c3337375c3030305c303131585c3236375b73225c3237335c323637315c3236325c3334375c3233345c3230305c303131763b5c3030305f5c32373327755c3033315c303037705c5c375c3232375c3334325c3033325c3230375c3231375c3230375c323335335c3234315c3031345c3236325c3033372829505c3031305c3231335c3235365c303337285c3234306d5c3330335c303030315c3330315c3231375c333730425c3033355c3233305c3030335c3330365c3230325c3032345c3231315c3234345c323036765c3031305c303332375c3331305c3334355c3231325c3337355c33343623605c3330375c3333345c3232335c303337747a5c3334335c3031355c3334355c3235335c3230355c3237335c303337445c3330355c3334335c3032305c3233364e5c333730666c6e5c3231315c3236377c5c3237335c32333075665c3331325c3031347d5c333131304e5c3332315c3335335c3231343f5c3232365c3335335c3137375c3032375c3235365c333733755c32323125515c3232335c3032335c3236345c3233315c303033235c3335373b7c5c3230305c3231346c5c3232335c3233365c3030375c323536305c3333365f5c33313631785c33333040415c3232323b5c323331365c3030325c3235345c303331715c3331305c3033345c3233375c323730315c3337365c323536435c3331365c3030373c5c3334335c3334365c3336325c3334345c3231335c3330363b3c5c3233355c3336314c5c3333305c3331346d5c3237335c3334355c3331335c3031365c3235345c333331415c3231375c323731265c3031315c3333323d715c3230375c3336325c3331355c3330325c3332363e5c3232375c3231335c333035305c3236346a64455c3231315c3331345c323031594b5c303334225c3337375c3030305c303233312a315c323134375c3033305c3331375c333132735c3236376b5c3335345c3237375c3030365c3236316b725c3330356277765c3033305c3331305c3032313646485c3033345c3336315c333037275c3033345c3336342a5c3333375c3333356c7c5c333137615c3334335c3230365c3231365c3033305c3232345c3230305c3230305c3230365c3236365c3232355c3234355c3033334e5c3332307e66715c323630675c3232305c3334345c303334715c3236305c3033375c3232376b797d2e5c3233315c3334335c3234355c3333345c3032304b2c5c3334363d5c32373045425c32373347405c3033335c3334355c3331305c3337315c3236365c3231365c3234305c3231372b5c3033315c30303630505c3237305c3231377c495c3332364f2f5c3030315c3330365c3336355c33333637235c3031345c3031363a5c33343470795c333530795c3335335c3335306a4a5c3336335c3231375c3031375c3337305c3233365c3033375c3236335c3231305c3330315c323236585c3331345c323032425c323036355c3033335c3033333b5c323030665c3333315c3236375c3230355c3231345c3230315c3332305c3030305c3030315c3331305c3033375c3335325c3237335c3231353e5c333432495c333034625320715c3033365c30313028705c3337375c3030302a5c30323249285c323730392460635c3237375c3033315c303034285c3236355c3332345c3031335c3234364024545c333437245c3032325c3031365c3332335c323136315c3333375c3234377e5c3233375f43555c323333545c32303123323f5c3233315c3033325c3030315c3237305c3236335c3330325c3335325c3032347c5c3237345c323232475c30333778673d305c3333315c3337335c3234375c3033313e215c3332367e5c3331325d3f5c3334375c3233375c3331355c3236375c3033335c3237326d705c3330354a5c3336335c3336375f5c3033306e5c3330375c3232315c323036685c3337345c3332335c3330345c303336295c3033325931245c3332324463245c3236345c3333335c3031305c3336325c3336305c3333334a5c3236375c3331305c3030325c3334335c333434205c3336315c3230305c3234305c3334306c5c3031335c3033335c3033315c3335332f5c3334325c303133305c3237314946415c3033335c3236375c32353328515c3232315c323232785c3334335c303033775f5c33353636715c3236355c3236303f5c3231302c5c3330325c333435255c3033315c3030346e5c3333365c3235345c3234314646495c3334335c3231345c3031355c3333355c3137375c3237305c3333315c3330365c3332365c3330375c3230305c3331375c3334335c3333355c3331372f5c333537635c333333215c3032315c3236365c3335305c3330325c3334323c735c3237335c3334345c3033305c3333335c3336335c3030303b795c3137375c3330335c3334355c3233355c323131375c32313732645c303036585c3231305c3232305c3231305c3233305c32363461715c303336395c3333355c3232345c3334336f5c3331355c3230315c3333335c3331335c3337365c3033372c5c33353441635c3333375c3333375c3330345c30323661725c3232325c3231345c323032376f56505c32343323245c3336315c3330365c3030365c3335365c3237375c3333346c5c3334336b605c3137375c303230595c3230355c3331324a325c3031305c3333355c32373559425c3231345c3231345c3232335c3330375c3033305c3033335c3237325c3337375c303030715c3236335c3231355c3235355c3231375c3030305c3233335c3330375c323331325c3030332c4448444c5a305c3237305c3231375c3033345c3335365c333132715c3236375c3334365c3330305c3335355c3334355c3337375c3030305c3031375c323236765c303233785c3336332640655c3231305c3231315c3031305c3231315c323133465c3032375c3032315c3334335c3233355c3333314e365c3337345c3333305c3033355c3237345c3237375c3334315c3336325c3331365c3330305c3031375c3137375c3137375c303230595c3230355c3331324a325c3031305c3333355c32373559425c3231345c3231345c3232335c3330375c3033305c3033335c3237325c3337375c303030715c3236335c3231355c3235355c3230315c33373441665c30323729285c33313023765c333635655c30313232324f5c303334606e5c3335335c3337355c3330365c333136365c3236363c5c3030326f5c303336645c3331305c3031345c3236315c303231215c30323131685c3330325c3334323c735c323733295c3330365c3333375c3233335c3030335c3236375c3232375c3337343e595c3333304d5c3334335c3331345c3233315c3030315c323236222422262d5c3033305c5c475c3231367765385c3333335c33363360765c3336325c3337375c3030305c3230375c3331333b5c3030303d5c3337355c33373441665c30323729285c33313023765c333635655c30313232324f5c303334606e5c3335335c3337355c3330365c333136365c3236365c3030375c3336315c3030355c3233305c5c5c3234345c323433205c3231355c3333335c3332355c323234285c3331305c3331313c715c3230315c3237335c3235375c3336375c303333385c3333325c3333305c3336305c3031315c323734795c32323320325c333034445c323034445c3330355c3234335c3031335c3231305c3336315c3331365c3335345c3234375c3033337e6c5c3031365c3333365f5c3336305c3337316761375c32313732645c303036585c3231305c3232305c3231305c3233305c32363461715c303336395c3333355c3232345c3334336f5c3331355c3230315c3333335c3331335c3337365c3033372c5c3335345c3030305c3336375c3336375c3336315c3030355c3233305c5c5c3234345c323433205c3231355c3333335c3332355c323234285c3331305c3331313c715c3230315c3237335c3235375c3336375c303333385c3333325c3333305c323231755c333133275c303136445c3234375c3031303739315c3236305c333330325c3030365b5c32313630725c3031367a6d6c5c3337355c3332365c3330375c3331375c323233785c3336332640655c3231305c3231315c3031305c3231315c323133465c3032375c3032315c3334335c3233355c3333314e365c3337345c3333305c3033355c3237345c3237375c3334315c3336325c3331365c333133365c323336355c323236795c333435314f5c3231313e555c3031355c3032345c303037705c5c5c323030335c3336325c3031355c32373062405c3033355c3237345c3237365c3330363c205c3030375c333230297d5c3032345c323035705c3236325c3231345c3334335c3033335c323431715c3337355c333337515c3337365c3332305c3337355c3137375c3237327134725c30313163575c5c5c323035605c3031305c3333345c3234354f5c3334325c303137235c3335306b5c3331325c3236345c303135796e5c323236395c32323437505c3335315c3237355c3031375c333130725c3331345c3032355c3330365c333035505c3030325c3330365c323735715c333637472a5c3032345c3033305c3237355c30333348735c3236355c3230335c3235335c323131245c3333325c3334355c32313464675c3032315c323430393b5c3032375c3233375c3235373c5c3033365c3233302a5c3235345c3031355c303332285c3234325c3230315c3030355c30323451405c3030355c30323451405c3030355c30323451405c3030355c3032355c3032345c3236375c3031335c3031332a5c323630725b5c3234365c333234665c303335405c3334345c3230315c333037515c333730645c3336345c3030375c3033345c3333365c3237335c3235375c32313328515c3033305c33313121505c3033306e5c3231305c323236385c3031332077425c3230335c303337755c3337325c3032315c3331303c5c3231345c3032335c3033305c303037492d5c333032425c3331325c3235345c3033345c3232365c3335315c3236355c3031335c3031365c32343072405c3334335c3235305c3337354f40715c5c5c3335335c3032365c3235335c323733735c3237326c505c3335375c323736265d5c323532715c32303272385c3033345c3336353e5c3231355c3337355c3332365c3330375c3232326b5c323736325c3231365c303131725c3232334a5c3333335c32303173715c303336783f772c4a715c3230335c3236315c3230315c3334335c3230355c3331375c3331335c32363544595c303233785c3335345c30313737645c33363340575c3032327c5c3336315c3335355c3336325c3234333d5c3031315c3337315c303036315c3232345c3330315c3334305c3031372b5c3236375c323236365c3030333d5c3331305c3335335c3032365c3235335c323733735c3237326c505c3335355c323736265d5c323532715c3230325c3333315c3033345c3031367a5c323337465c3337365c333533603a5c3330355c3235325c3335365c3333345c3335365c3233335c3032343b6f5c3231315c3232376a5c323334605c323636475c3030335c3233365c3234375c3332315c3237375c3237325c3333305c3336305c3234375c3336315c33353061315c3231365c333436585c3330325c3232305c3334305c3233305c3336315c33343526715c3336337c5c3230335c3033305c333731795c3334305c3031372b5c3234305c3336325c333736415c3337347a5c3033304c635c3237315c323236305c32343438263c79495c3233347c5c333337205c3330363e5e785c3030335c3331325c3335303c5c3237375c3232315c5c2c7b5c3235315c3332362d57765c333437745c3333305c3234315c3333337c4c5c323733545c3334335c3030355c323632385c3033345c3336353e5c3231355c3337355c3332365c3330335c323233545c3236375c3232324f2c795c3233335c3336305c323534545c3330325c3334305c323030715c32303246385c3335335c3333375c3332315c3237375c3237325c3333305c3336305c3230375c3336315c33353061315c3231365c333436585c3330325c3232305c3334305c3233305c3336315c33343526715c3336337c5c3230335c3033305c333731795c3334305c3031372b5c3234305c3336325c333736415c3237347a5c32353427315c3333345c3331335c303230525c3033345c3032335c3033363c5c3234345c3331363e6f5c323230635c3033372f3c6d5c3336325c3237325c3031372f5c33343461635c3333375c323232755c3232335c3331335c333030715c323735775c3231355c3331305c3330335c3030335c3231365c3237315c3033345c3033367a5c3033367a5c3337325c3033325c3232325c3237343e5c3331335c3330365c3330375c333535315c3237344938287c5c333035595c3232335c3031335c3330372a5c3234375c333637635c323436625c3033305c3334335c3337355e5c303036365c3235375c3232375c3332375c3335307e2d5c3231315c30323424264f285c3232352c5c3235305c3230306d3d4e5c3334362b5c3231346d5c3231355c3230305c3335305c3030305c3330375c3333355c303334445c3030355c3236345c3237315c3335303456765c3232335c3235315c3234355c3334325c3231305c3231335c3335375c3233315c3032345c30323620313d5c3030364b7c5c3235325c3030315c3333355c323730635c3030335c3232356e5c3030315c3031345c3032365c333734725c30313163575040605c3031305c3031345c3234354f5c3334325c303137235c333530685c3032305c333532285c3234325c3230305c303132285c3234325c3230305c303132695c3232305c3031315c303235395c3331315c3030345c333437695c3330375c3033305c3335375c333230755c3335315c3336355c33363435525c3335325c333731605c323136395c3336373a5c33303657715c3031365c3230355429655c333133315c3333335c323235205c3033365c3230375c3033355c3336335c3332305c3232315c3330325c3335325c333736275c333034325c33353632265c30313062245c3231355c3232337c5c3234305c3032355c333131605c3231335c333336235c3231365c3030315c3033365c3330375c323330403b5c3234335c3235345a5c3235365c3335355c3331365c3335315c323631435c3237365c3337305c323331765c3235315c3330365c3031315c3331305c333430735c3332345c333732375c3336375b5c3032305c3237375c3231302c5c3330325c333435255c3033315c3030346e5c3333365c3235345c3234314646495c3334335c3231345c3031355c3333355c3137375c3237305c3333315c3330365c3332365c3330375c3231315d5c3337305c33363142385c323132595c323430655c3333325c3334375c3331355d5c323432385c3331315c3335325c31373776365c3334305c3032345c3330315c3334305c3030335c3032376d5c3230335c3331335c3331365c3233375c3330375c3237335c3233365f5c3333365c3330375c32363642236d5c3332315c3230355c333034785c333437775c333130315c3236375c3334365c303030765c3336325c3337375c3030305c3230375c3331333b5c3032355c333037635c3333375c3233375c3330345c30323661725c3232325c3231345c323032376f56505c32343323245c3336315c3330365c3030365c3335365c3237375c3333346c5c3334336b605c3137375c303230595c3230355c3331324a325c3031305c3333355c32373559425c3231345c3231345c3232335c3330375c3033305c3033335c3237325c3337375c303030715c3236335c3231355c3235355c3231375c3030305c3233335c3330375c323331325c3030332c4448444c5a305c3237305c3231375c3033345c3335365c333132715c3236375c3334365c3330305c3335355c3334355c3337375c3030305c3031375c323236765c303233785c3336332640655c3231305c3231315c3031305c3231315c323133465c3032375c3032315c3334335c3233355c3333314e365c3337345c3333305c3033355c3237345c3237375c3334315c3336325c3331365c3330305c3031375c3137375c3137375c303230595c3230355c3331324a325c3031305c3333355c32373559425c3231345c3231345c3232335c3330375c3033305c3033335c3237325c3337375c303030715c3236335c3231355c3235355c3230315c33373441665c30323729285c33313023765c333635655c30313232324f5c303334606e5c3335335c3337355c3330365c333136365c3236363c5c3030326f5c303336645c3331305c3031345c3236315c303231215c30323131685c3330325c3334323c735c323733295c3330365c3333375c3233335c3030335c3236375c3232375c3337343e595c3333304d5c3334335c3331345c3233315c3030315c323236222422262d5c3033305c5c475c3231367765385c3333335c33363360765c3336325c3337375c3030305c3230375c3331333b5c3030303d5c3337355c33373441665c30323729285c33313023765c333635655c30313232324f5c303334606e5c3335335c3337355c3330365c333136365c323636265c323033585c3236355c3237316d5c3236313b5c3237335c303134645c3031305c32333323245c303136785c3334335c3232335c3231367a5c3032356f5c3335365c3236363e7a5c3233335c3330375c323331325c3030332c4448444c5a305c3237305c3231375c3033345c3335365c333132715c3236375c3334365c3330305c3335355c3334355c3337375c3030305c3031375c323236766c685c333736345c333733545c3334357c5c3336367650585c3031355c323036355c303333415c3330325c32333426415c3333355c3236345c3031345c3032315c3230335c30333638285c3031325c3032375c3031335c3033365c3334375c3031355c333334735c3236305c303132245c3030345c3231345c3337345c333631325c3336365c3030375c3237305c3337375c30303068715c3336355c333634385c3233365c3237305c3331355c3031325c333536495c3031305c323637485c3333355c3234315c3032325c323531655c3336325c3236315c3236345c3235345c3231325c3237335c323130295c3233345c3031355c3233305c3033345c303134635c3231355c3234305c3032315c3031375f6e775b5c333034773b5c333435475c333135225c333535635c3330375230307d5c3236303e5c3232345c33303449455c303234505c303031455c303234505c30303145345c3331305c3030345c3231325c3233345c3334345c323032735c3236345c3334335c323134775c3335303a5c3336345c3337325c3337325c3033325c3234352e5c3236336e5c3231325c333330245c3032345c3031325c3335362447405c323130485c3337315c3231375c3331335c3330375c3030345c3336355c3337365c333533645c3231355c323534405c3030355c333732695c3232305c3031315c303235395c3331315c3030345c333437695c3330375c3033305c3335375c333230755c3335315c3336355c333634355c3331316a5c323336325b5c303330415c333337322a7c5c32303256504b5c3233365c30313659765c3336304e5c3330375c3033305c3331325c333632715c3330315c3031355c3334355c3336335c3237325c3231375c3231365c3331305c3237335c3031335c3031365c3333315c30323062525c333232715c323732555c5c7c5c333030205c3331364a2e385c3335305c3137375c3230345c3335355c3336325c333233765c3030335c3332325c3231355c3334346a5c3236315c3236315c30323262405c3033307e5c3335315c3237305c3033315c3030335c323336385c3335323a5c3334335c3237375c3234315c33303427585c3236355d5c3333335c3233355c333233625c3230377d5c333631325c333535535c3231345c3032335c3232315c3330305c3334375c3235315c3336346f5c3335365c3236363c465c3334375c3330365c333733212e5c3232325c5c5b2f5c3333375c3333345c3335315c3230305c3231335c3233365c3337375c3030305c3237335c303333705c3033323e785c3330375c3232375c323336365c3031355c3232355c3235365c3237347d5c323630485c3032325c3334315c3334326d5c3331325c333132255d5c3233365c5c675c3332375c333637635c32323030415c3334305c3031372b5c3236375c3232375c3232342e3b5c3033365c3334325c333736205c3236335c3031335c3232345c323234645c3032315c3237337a5c3236325c3230355c3033315c303331275c3231363037755c3337365c333433675c3033335b5c303233435c3235345c3333325c5c31585c3333355c3333355c323036325c3030344d5c3336325c3336325c3030373c715c3331315c3330373d365c3236375c3336375b5c3033373d5c333334785c333633735c3331335c3337335c3333305c333631215c3032315c3236365c3335305c3330325c3334323c735c3237335c3334345c3033305c3333335c3336335c3030303b795c3137375c3330335c3334355c3233355c3233325c323332475c323135565c3334325c3334355c3236365c3331305c3332325c3331325c3234305c3033345c3030345c3336325c333030505c3031365c3032355c3237365c5c5c323134315c3030305c303030415c3033365e5c3030365c3031325c3030325c323030585c3336335c3031375c3230335c33363732785c3232375c3336365c3237355c3336315c3334365c323435765c3236334d3d5c3234355c3330325a234e5c3237312a5c3235325c3030325c3233375c333731655c3337375c3030304c5c3236323a605c313737775c303337275c3333315c3232355c33363024775c3332327c5c3033375c3337355c3235345c3335376e5c3331305c3231325c3033353b595c3330345c323631355c3330365c3335355c3230324e5c3030315c333336762f39565c3330303d385c3335315c3330375c3232375c3336375c3230365c323235765c3232375c333732655c3236345c333531325c3331365c303336307c5c333035395c3030345c3334335c3233365c3330335c3237367b5c3031375c3234305c333531585c3332315c3236372b5c323637775c3137375c3237345c333630325c3230345c3234334e5c323535365c3337355c333435395c3333375c333437265c3332375c3334305c3332315c3336305c3137375c3230335c3337345c3137375c3334315c3231375c3230365c3337375c3030305c3236345c3330375c3330345c3031335c3237375c3032335c5c2d5c3233355c3233345c3332375b555e5c3333345c3331335c323737685c3030315c3232375c3031335c3031315c3333335c3332335c3033303b7b7d5c3333347e5c3335375c3332317e2b7e5c3332345c3033375c303132355c3235375c3031305c3335325c3237324e5c323137625c3237325c3335355c3336355c3333345c3032325c3330356d5c3031345c3033327b5c3330365c3033315c3231305c333332375c3335365c3231357039275c303033275c3335365c3232315c3230365c3331314e5f5c333431375c3230355c3236345c3235375c3032327e5c3332335c3333375c3032315c323535355d3a3b5c333133665c3237334c452c5c303032415c32323070727c5c3237375c3232335c3335365c32333742315c323134285c3033375c3237335c3333335c3337355c3234325c3337365c3030305c3137375c3330325c3237325c3231365c3333335c3330375c3237365c3030315c3236315c3032305f5c3335315c3231355c3334365d5c333332435c303036625c3233365c3030355c3030305c3236345c3232322a205c3033315c5c7b70335c3233365c3030314e6b5c333135424e3b5d5c3333375c3337325c3237315c33363354255c3233305c3332325c333030545c323531415c3330355c3330335c3233325c3234355c3332372b724b5c3233315c3333355c3235377a5c3331355c3235355c3335345c3332315c3333345c3337365c3331335c3033375c303136352f5c3031337c5c3030375c3232365c3331375c33303422585a5c3334345c3331352c5c323332755c333234607963395c3337355c333430605c323730625c3032375c3232315c32323047205c323630205c3030345c3334325c323737617b5c3237315c3336345c3233375c3337304d5c3336345c3231305c3335345c3334375c3237345c3230325c33303751655c3231315c3232336064535c3230355c3330335c3032365c3031315c3332345c3330364e385c3335375c333037405c3233365c323135635c33373343786b5a5c3337305c303131375c323134215c333335665c3235335c303130595c323430455c3330345c3232305c333334222e5c3032355c3336305c323330562c5c323430215c3330305c3331305c333332465c3331345c3033355c3233345c3231375c333534435c3334303b5c3233333f5c3030345c3333375c3335335c3337325c3230355c3237345c333230375c3231302e5c3033365c33363639505c3236345c3031365c333130305c3234305c3033355c3235325c3237305c3033355b5c3033315c3030305c33343470765c333431355c3231325c323134675c3031305c3330375c3234325c3137375c3234315c3335325c3332305c3230355c3032355c3231315c333031535c3330333e655c303132725c3332375c3337335c3236365c3231325f7b5c3337345c3233315c3336353d5c303234515d675c3332375c3030355c30323451405c3030355c30323451405c303035545c3237365c3237335c3032367b646721405c3337315c3230315c303037605d5c3331325c3031335c3032365c303132715c323030495c3335325c3030375c5c5c333630322d5c3332375c3230305c333734615c3337355c3234313c5c3033315c3336305c3337324b5c3231333b5c3237355d5c3235367564525c333337665c3236345c3231343d5c3330316d5c3231315c3336375c3336305c323030235c3030325c3234305c3334315c3331305c3334375c3033305c333434662c5c333437385c333233575c323233395c3236315c3033305c32333238583a5c3236355c3334365c3234335c3032355c3332355c3237335c3033335c3033362f5c3336314471795c3335325c3033355c333231475c3032335c3331312f5c333134415c3337335c3235375c3237305c3032345c3033305c3033315c3031325c3333315c3334335c3030305c303032715c323635447e455c3235365c3337305c3331345c33303667315c3232375c3032312b655c3032325c3334325c3032335c3236345c32363027685c3331365c3333363e685c3233335c33333472325c3031364c5e2f5c3334325f5c3333325c3234375c3337335d5c3333316c5c3236343b5c3233306d5c3333315c3231335c3330365c3236325c3333355c3230305c333132315c3230315c3232335c3334345c3336355c3030375c3031345c3030315c3330315c333130275c3230335c3230325c323334545c3337375c3030305c3033324c5c333637255c3334325c3332315c33333523624a465c3332373f5c3330335c3232315c3331335c30333728615c323037385c303334675c3233363d395c3233362a5c323237735c3334375c3233375c303235645c3332315c3332335c3333335c3337375c3030305c3334345c3236325c3337375c3030305c3334344f605c3332343c4f2b5c333034625c323135655c3337355c3334375c3033335c5c5c303036405c3233335c323630415c3330347c605c3032345c3330374f5c333635635c323430555c3333315c3233352f5c3231316e5c3234365c3232315c333330215c3330345c323031625c3030305c3330325c333033315c3232325c323734305c3333315c3330315c3033335c3237305c3033355c3236365c303136576f5c3331335c3334345c3231315c333631605c3233365c3237325b5c3331315c3237355c323236435c323736555c3033335c3336365c3335345c3337315c3233335c3336373c305c3333335c3330305c3336373d30365c3236362f5c3231325c3230315c30323555745c3232325c3331324a5c323730565c323235545c3033355c323733393f5c3237315c303330615c3236335c3230315c3337345c323630365c3233375a5c3234335c3337345c3333375c3233302e2b5c3331315c3235355c3337345c3137375c3337345c3232365f5c3337345c3231315c333533435c33303437385c3330325c3235335c3032357558465c3335305c3233332d5c3033315c3333335c3336375c3236325c323335465c3335365c3030315c3335315c32363072365c3337345c3234305c3336315c3031355c333136305c3235325c3330355d565c3032315c323732265c33313346765c3337355c3335345c323437515c3237335c3230307a6c5c3033345c3231355c3237372f5c3232325c3330355c33363150225c3235325c3235365c3232325949575c3031325c3332325c3235325c3230335c32363767275c333637235c30313436703f5c3232365c3030365c3332322f5c3231325c3230315c30323555745c3232325c3331324a5c323730565c323235545c3033355c323733393f5c3237315c303330615c3236335c3230315c3337345c323630365c3233375a5c3234335c3333375c3337325c3337335c3230335c3337356b5c3331315c3237375c3334375c3337375c3030305c3337364b2f5c333736445c3336355c3234315c3334325c3033335c32333461555c3231325c3237325c32353423744d5c3232365c3231345c3335355c3337335c3333314e5c323433775c3030305c3336345c333330395c3033337e50785c3230365c3334375c30333055625c3235365c3235335c3031305c3333355c303233655c3234333b7e5c333636535c3235305c3333355c3330303d365c303136465c3333375c3232375c333131625c3337305c3235305c3032315557492c5c3234345c3235335c3230356955415c3333335c3236335c3232335c3337335c3232315c3230365c303333385c3033375c3331335c3030336d5c3335375c3031375c333734413a5c3236365c32343769615c3033365c3232365c333132275c3232315c3031302c5c3330335c3033305d5c323337335c3030315c3031305c3330335c3030305c3233315c3030335c3231375c3235305c3030306d6b5c303233495c323733275c3337357d5c3330365c3236345c3237305c323333295c32353752345c3235315c3332365c3237345c3234345c3332324b5c3232365b5c3237375c333733745c3336345c3330315c3334325c3033335c32333461555c3231307558465c3335305c3233332d5c3033315c3333335c3336375c3236325c323335465c3335365c3030315c3335315c32363072365c3337345c3237355c3333375c3230315c3235365c3234345c3332345c3233365c3333315c3231305c32323254415c303233725c3230346c5c3331335c323334645c3032345c3334335c3230355e395c3330365c3332315c3332336831797d5c3237355c3236305c3334315c303230332964755c303232445c30323030515c3032375c3331345c3333375c3237335c303330615c3231365c3030375c3332375c3234363e4f595c3336302e5c3233305c3331322d5c3332355c3235355c3333345c3331365c3233305c3333365c3331365c3030325c3236325c3335355c3232305c3336325c3337375c303030273d5c3031305c3330363e5c3336305c3334305c3337345c3237375c3237325c3335315c333533635c33353236475c3237345c3337343e5c3230315c3334355c3337335c3033345c3231325c3232325c3331325c3237365c5c4c5c3332323c3b585c323137315c3237316f5c3333355c3231365c3334307a5c3334305c3231365c333333735c3032375c3235315c3333335c3233355c3332365c3336315c3033355c3331365c333731515c333633485c323733585c3336315c3332345c3231345c3031345c3033376c5c3031375c323435703e5c3031315c3332335c30323646522d5c3333325c303331633b5c3231325c3331315c3330335c3030305c3236325c333634635c3236335c323334615c3237325c3230315c3331325c333630725c3234335c3331325c3336342a5c3236325c3030325c3231322b3b5e5c3336315c3031365c3233335c3334315c323135367d43555c3237335c3231365c3330325c3330365c3031305c333332596e265c3334315c30323146335c3232365c3335315c3333375c323437535c3333335c3234355c3033335c30323329465c3031315c3331324e5c3331315c3032315c3335335c3336375c3030365c3333325c333335585c3030377d5c323730725c30303229455c3333325c3331327731235c323134635c3231364752725c3030302c5c323736495c3334325c3337375c3030305c3032345c3235365c3233375c3031345c323230425c3230375c30313231265c333435205c3030305c3031365c333037565c3331325c3030305c3237305c333731485c3337335c3234335c3334355c3030345c3335355c3031325c3030345f3e5c333734625c3337355c3236375c3231365c323431792d5c3231375c3230322c3c5c3335334c5c323230752d525c3031355c323535385c3333325c3235325c3330375c3331335c3031325c3031305c3331365c33323520365c303136405c333430606c5c3337315c333533535c3337305c3332335c3334334d6a577b5c323335664759475c3032315c323133785c3334335d5c32373467385c323134605c3336315c3332305c333632765c3231375c3335365c3231355c3237345c3032335c333036535c3231335c3236325c3332345c3337305c323334575c3033305c3334355c323730695c323732705c3237345c3335355c333235256f5c3237355c3236355c333730687d295c3334326f5c303236492d5c3331375c3232355c303131645c3232315c3031375c333137265c3332305c3235375c3237345c3031355c3235355c3237335c333434535c3332355c3032315c32303742305c3031375c3030345c3030305c323334765c3234315c323535355c3336355c3330324c5c3030345c3234345c3033342a235c333032575c30313059715c3232325c303230725c3234315c3236305c3030375c3030335c3030335c3033345c3030355c3337317c465c3330335c333432665c3237315c303133285c3237325c323235755c3033305c3231335c3030375c303131715c3032305e5c303031535c3233345c3230345c303333585c303230703d5c3331374c5c3031355c3237365c3230375c3334315c3331375c3032305c333332785c3231325c3332344b5c303033485c3332325c3032375c3231355c3234345c323036485c3230365c3334315c3230335c3033305c3333345c3337305c3231375c3230335c3336325c3232323f5c3033375c3237335c3231375c3232334a755c333431555c3337335c323537535c3332345c333133385c3230375c3030315c3233325c3331335c3333315c3332315c3232355c3234375c3333325a3f5c3232365c3335315c3337355c33363737615c3237335c32323636535c32373269415c3330325c3235305c3232323237295c3032315c3230325c3331355c3231305c3330365c303330645c323334745c3335335c323334605c3335345c3335337c3b5c33343249625c3232365c3333305c3331312b5c3233305c3332342b5c3234315c3232313a5c3030355c3030345c3230305c33313257245c333434275c3030345c3231375c3237305c323433236a5c3236327131445c3236315c3230305c32353224642f5c303331505c3332306d5c3333345c3030375c3232343736235c3334315c3230363a7d795c3033337e4b5a5a5c32313025215c3031345c3230315c303330645c3030365c32303428615c323632315c3232365c3337315c3032375c3031355c3335355c3233375f4c2f415c3336345c3337325c30333753785c3031335f5c323236495c3335355c3232305c3235332c5c323130465d5c3234335c303330605c323132585c3335373b5c3032373f315c3030375c3232325c3237305c3333335c3331365c3330325c3237375c3237335c3336367d5c30323266785c3333375c3331355c323132485c333435725c3033305c3335374c6e5c333032205c333131215c303234735c3335375c3331375c3332335c303035575c3334363f5c3030335d5c3331305c3235325c3331325c3033315c323630445c3237335c3234325c323332205c3033315c303136425c3336335c3336325c3030315c3330365c3031325c3235315c3334335c3033334e5c3030375c303333635c333732335c3330315c3236325c3234375c3333315c333336212c5c32343641245c3230345c3330365c3332315c3335355c3334305c3032305c3234333f225c3334335c3033334a5c3235375c3235305c3030375c3230315c3236376a525c3032335c3236355c3336343a4a285c3234325c32333121455c303234505c3030314d325c303031225c32343739205c323230765c323334715c3231365c3337353b5c3336345c3337325c3337325c30333275725c323736205c3336315c3030315c3236315c323636555c3033335c33343575505c3331325c303336335c323236215645775f2f5c3231375c3237325c3337355c3031305c3334345c3033365c32333026305c3031313c435c3334325c3032355c32363550365c3237363e5c3336325c3235375c323234585c3231345c3030355c323231595c3232355c3232335c3231375c3237325c3334335c3235305c3334345c303336415c3030345c3330375c3334375c303336285c3336313c764a5c3336365c3330305c3233305c3332305c30303225635c3033315c3333325c3234305c3033355c3235345c3235345c3031325c3030305c3237305c3337315c3031303c602838505c3231325c3236315c3336305c3237375c3032343e335c3335305c3233365c3031345c303337665c3237375c3332345c3334335c303233365c3334365c3231365c333335405c3232315c3336365c3230325c333330605c3235325c323532405c333030555c3030305c3230305c3031365c3332355c303337285f5c3232335c3334365c3233375c3032347e5c3332315c3233376f5c3031365c323332665c3233332b5c32333179335e5c323636375c303032305c3333335c323237695c3334375c3335365c3232315c3331305c3334355c3030375c3030305c3030355c3032315c3336335c3332345c3235374e5c3233365c323232675c3231315c3231355c3331365c3336325c3337345c3237355c3336325c3334322b252e5c333133575c3336372b5c3333335c3334367b5c3335365c3236335c33343364485c323437285c3232325c3231355c3231355c3337335c3236313c4421705c3333372e414c5c3231375c323332275c3335375c3233367b5c3033345c3233305c3337303b5c3237375c3032354a5c3234302466685c3333315c323136545c3230305c3033305c3030315c323334635c333435405c303036335c3033363a635c3331335c303034705c3235335c3236335c3334375c3333335c3331375c3231325c3233325c3337355c3333345c3333335c3334315c3232323b54235c3334355c323135225c3334335c3033315c3033345c3233355c33313248615c3331375c3033355c3337315c3337375c3030305c3230305c3334345c3233375c3033315c3335335c323633335c3032365c333234255c313737315c3230345c32333064545c303134405f5c3233315c3236305c3230335c303134315c3330305c3336365c3335355c3230315c3236375c3232355c333433695c3235355c3032326c5c3337315c3233325c3233346f5c323237455c333332305c3233335c333731255c3337325c3337365c3230375c3332305c3032373a5c3337345c333237532c5c323436325c3330345c3230305c3231315c3237325c3030323e435c323634735c33363270407c5c3030315c3333302f555c3031335c3336325c3334375c3235355c3330345c32343366255c3233355c333036542e5c3337305c3331305c3333345c3234375c3331335c3331316f5c3333355c333630793c7b5c3236374c7c5c3233365c3033356f5c3334335c3033356e5c3032355c3333325c3236375c3331365c3331305c33303438575c32313140385c303132375c3033375c3333355c3336305c3330335c3033345c303137615c3332335c3030336d5c3233332f5c3033376b5c3232365c3333305c30333768495c3332315c323130715c3033345c3332365c3335305c3030315c3330365c333134315c333034635c303134365c3336303d5c323733606d4b5c3033334f5c3236335c3031305c3336315c3330365c5c5c3333375c3237354e6b5c3334345c3237375c3331345c333636745c32333660545c3231315c3235365c3033345c303236405c3237335c333433232a7c5c3237345c3232365c3337355c3333375c3030375c3232335c3330375c32373372315c3336323a2b5c323331515c3232345c3337315c3232335c3331325c303131505c323432485c3331305c3331325c3233372c5c3032366c463046495c3330375c323733675c3030307c5c3233364b615c33363137515c32303155665c3236355c3230325c3334315c303131575c3030335c3331325c3032315c3335365c3333335c3236335c3030355c3237364e5c3033306d5c3334307d7a606d5c333531745c3231375c3231305c333332455c3330325c3330375c3033345c3334326b46775c3231345c3230312c405c3234315c3330375c323236375c3032325c3236315c333630465c3333365c3334307e5c3030307c5c323333475c3032354a5a5c5c5c333636705c3237344f5c323235625c3333372c6a5c3336325c3237375c3335372b7e3b7e27755c3030365c32343124255c3031325c3230375c3232335c3230305c3230305c3331335c3032315c3337315c3332355c3230325c3030325c3331343c5c3237375c3232355c3230365c3334335c3330305c33303742785c3330315c3333335c3236315c323436785c323336685c333434525c3030335c3232375c3030315c30303233215d5c3331305c3234305c3032305c3235344a5c3230325c3031302c5c3237305c3337315c323632365c303134725c32343367316d5c3334353c485c3332305c3232365c3233325c303237785c3333315c3031375c3232325c303030603c5c3234315c3237305c3334323e5c3031305c3330374f5c323537236f5c3331316f4c5c32313563725c323532645c3031305c3330305c3032355c3031355c3031365c3330305c33303024632d5c3336322e5c303330635c3234375c3332375c3332335c3031335c3332375c3237315c333635495c3234365c3235365c3231375c3234307c5c3033355c3235325c3234346a7e5c3331345e5c3033315c333433635c323035645c3330314d5c323430216f5c3237305c3237305c3337315c3230336d5c333536315c3330365c3333355c323733535c3333377c25725c3033354c484a5c323030645c3333365c3230355c3031325c3334335c303035545c3032325c3031325c3031375c3335365c3236305c3033345c3231365c3230345c3030355c3033305c3333335c3033375c3330375c323736295c3336315c3334345c3137375c3031305c3337342d6b5c3235325c3031335c30333135595c3234345c323732365c3231315c3031345c3232325c333731585c5c645c3232325c333736595c333435425c3030355c333037535c3230305c303136365c33353548345c3235375c333730285c303132695c3336315c3235325c3236375c3230303e5c33323477335c3234315c323237545c3031335c323035255c3031305c3331362d782b5c323631405c3033375c3335345c3231365c3230305c3030305c3237304b5c3032314e5c3233335c3334355c3232335c3236333e5c3137375c3033335c323337655c3333305c3031325c3333365c3330375c303233565c3332325c3333365c3332365c3232335c3337345c3232333e5c3233365c3336315c3331355c3332345c3235305c3231365c3335335c3334362e5c3336325c3235305c333036685c33303067525c3233305c3331335c3031355c3234305c3031345c3335355c3030375c3236315c3331325c3231365c323435365c3330355c3336335c3233375c3231355c323635795c3331365c3335305c333433475c3336325c3231315c3033335c3234355c323232355c3031345c3337315d5c323437775c333130393e5820762b5c3335325c323733635c333433755f5c3333335975595c3030345c3231335c3334305c3234335c3032335c3232305c323431335c323531715c323630675c3235305c333733385c3330315c3330315c3033305c3033375c3335345c3334305c303030305c3032335c3331355c3336353f5c3231365c3235335c3235325c3232305c333037416d5c3337315c3030355c3031345c323237235c3030315c3030335c303232325c303034235c3030345c3030325c3234305c3031365c333333785c3330305c3330305c5c5c3333362e5c3232375c3336335c3033344b5c3231325c3336326e5c3236355c3237375c333632595c3137375c333632275c3234315c3033375c3032315c5c5c323636705c3234345c323037555c3231306e5c3231315c3230365c3335305c3331365c3333375c3237355c33363270465c3335365c3030315c3335315c32363072365c3337345c3235303c43735c3231342a5c32363157555c3230346e5c3231315c3236325c3332315c3233355c3237377b295c3332346e5c3334305c3033365c3233335c303037236f5c3331335c3334345c3236317c545c3031305c3235325c3235335c3234345c32323652555c3330325c3236345c3235325c3234305c3335355c3333315c3331315c3337355c3331305c3330335c3031355c3233345c3031375c3334355c3230315c3236345c3231335c3334325c32343045555d245c3236325c3232325c3235365c3032355c323435555c3030376e5c3331364f5c333536465c3033306c5c3334305c3137372c5c3031355c3234375c3332365c3235305c3336375c3337365c3237365c3334315c3337375c3030305c32353579375c3337345c3337375c3030305c3337375c3030305c333131675c3337375c3030305c3331305c3233365c3236343c43735c3231342a5c32363157555c3230346e5c3231315c3236325c3332315c3233355c3237377b295c3332346e5c3334305c3033365c3233335c303037236f5c3331325c3031375c3032305c3333345c3334335c3031325c323534555c333235615c3033335c3234326c5c323634676f5c3333365c333132755c3033335c3237305c3030375c3234365c3330315c3331305c3333335c3336325c3337312c5f5c3032355c3030322a5c3235325c333531255c3232345c323235705c3235352a5c3235303b76725c31373772305c333033675c3030335c333731606d225c3337305c3235305c3032315557492c5c3234345c3235335c3230356955415c3333335c3236335c3232335c3337335c3232315c3230365c303333385c3033375c3331335c303033695c3336355c3235323d5c3337375c3030305c3235375c3237303f5c3332365c3237345c3233335c3337365c3137375c3337375c3030305c3334345c3236325c3337375c3030305c3334344f5a5c303336215c3237315c3330365c303235585c3235335c3235325c33303237445c333331685c3331365c3333375c3237355c3232345c33353237705c3031374d5c3230335c3232315c3236375c3334355c3030375c3231306e715c323035562a5c3335325c3236305c3231355c333231365a335c3236375c333537653a5c3231355c3333345c3030335c333233605c3334346d5c3337317c5c3232362f5c3231325c3230315c30323555745c3232325c3331324a5c323730565c323235545c3033355c323733393f5c3237315c303330615c3236335c3230315c3337345c323630365c3232317c545c3031305c3235325c3235335c3234345c32323652555c3330325c3236345c3235325c3234305c3335355c3333315c3331315c3337355c3331305c3330335c3031355c3233345c3031375c3334355c3230315c3236345c3337325c3332355c3033365c3337375c3030305c3332375c3333345c3033375c3335335e4d5c3337375c3030303f5c3337375c3030305c333632595c3137375c333632275c3235355c3031375c3032305c3333345c3334335c3031325c323534555c333235615c3033335c3234326c5c323634676f5c3333365c333132755c3033335c3237305c3030375c3234365c3330315c3331305c3333335c3336325c3230335c33303437385c3330325c3235335c3032357558465c3335305c3233332d5c3033315c3333335c3336375c3236325c323335465c3335365c3030315c3335315c32363072365c3337345c3237364b5c3032375c333035405c3231325c3235325c3237324965255c5c2b4a5c3235325c3031365c3333355c3233345c3233375c3333345c323134305c3333315c3330305c333736585c303333485c3237362a5c30303455555c3332324b292a5c3334315a5550765c3335345c3334345c3337365c333434615c3230365c3331365c3030375c3336325c3330305c3333327d6a5c3231375c3137375c3335335c3335365c3031375c3336355c323537265c3337375c3030305c3233375c3337375c3030305c3337312c5c3237375c3337315c3032335c3332365c3230375c3231306e715c323035562a5c3335325c3236305c3231355c333231365a335c3236375c333537653a5c3231355c3333345c3030335c333233605c3334346d5c333731755c323734375c3235355c3333354f7c5c3235325c3231324e5c3032375c33343467425c3233335c32323553725c323037625c3233315c5c5c3032323a5c3233365c3030325c3031365766535c3230325c3336305c3334355c3337375c3030305c3336365c3236365c3232316d766d5c3333365c303231335c3234335c3031305c323134605c3230325c3032345c3330365c3234315c3231315c3032315c3031345c303336325c3030376e795c3033337e4e5c3335375c33303156505c3235355c3330342e5c3232315c3331325c3031375c333132566f2c285c3331365c3330335c3336375c3330305c303033695c3330325c3334345c3033375c3232375c3033333a5c3235375c3333364e5c3232345c33323357475c333234515c3235335c3031325c3336305c3231355a6e5c33353249355c333233475c3235327a5c3233365c3336355c333430392f5c3032345c323036485c3234345c323135635c303032305c3235375c323234415c3231305c3330332824225c3335355c303331525c3333355c3236315c3231345c333436325c323737275c32373078722f265c3331315c3332375c333131787e615c3336325c333130307e5c3334325c3336335c333637575c323137415c3231365c3030365c3030365c3032375c3033335c3032375c3330377e5c3033345c3335305c3336305c3335365c3236345c3031305c323632452b3478605c32313440725c3230375c33353761415c3033305c3031335c3330375c33333523685c303030285c3033335c3232335c333333745c3331305c3032325c3031335c3033305c3030325c33303623665c3231355c3031335c3030305c32373372765c3230315c3331305c3333325c3237355c3230305c3033355c3030374e5c3230335c32343559455c323732285c3234325c3233305c3030355c30323451405c3030355c30323451405c3030355c30323457215c3336312f5c3330375a375c3330335c3337355c3031335c3337334f5a5c333234635c3332335c3335355c3232345c3337345c32353530525c3235345c3330305c3230365c3033305c303034655c3233335c3334355c333431575c3232335c323232785c333031654d5c3234355c32353322735c323135385c3237315c3331355c3333312d5c3333335c3333305c3230375c3330345c3333325c3237345a6d5c3234345c3237335c3234345c3232315c3333315c333130755c3333365c323436325c3331375c3236315c303132335c3230315c303330205c3233355c3231345c303037395c30303470415c5c5c3330375c3334325c333336325c3336315c3231375c3232312b6d5c3333375c3334365c3231345c3230315c3231305c33363263515c3336335c32353020205c3031345c323733435c3031345c3336315c33363770365c323035253c5c3235375c3330365c3233375c3236355c3337375c3030305c3230376e2e5c3236365c3335305c3333327e5c323435787c5c3236335c3236367b5c3231305c323232255c3334315c3237305c3033305c3030333b40385c3030305c323035385c3030305c3030305c3237355c3032335c333132752f5c3231365c3332365a5c323030574d2a5c3335335c333135605c3031325c3337315c3231365c3234305c3030355c3030345c333630705c3230335c3033305c3030345c303030385c3337335c3237305c3330305c303334273b5c333034525a735c3033373b2e255c333132625c3333345e21695c3334345c3333375c3335307a5c3334365c3237335c3334325c3232374b5c3330335c3032346f2f5c3233364b334a5c3030315c333130607043655c3030365c303136765c3032315c3332305c3337345c3234305c3334306d555c3231375c3031365c3334335c3330355c3332335c3331335c3033335c3231305c3230345c3237305c3232355c323234225c323734445c3030355c3231345c3232305c303130385c3231375c3235305c3031345c3233305c3335315c3231372c745c3333303679205c3337305c3235356e5c3333356c5c323536655c3031345640245c333330375c3032315c3236335c3232365c3337355c3333375c303134365c3233347d7b606d6c5f5c3032346c5c333231425c3235365c3233373b295c3333305c33343158225c3230365c3333335c3334355c3336325c3333375c3237335c30333023675c3030335c333731606d5c3233375c323534525c333533215c3137375c3235345c333731475c3337345c3337375c3030305f745c3237375c3331305c3336355c3233315c3237345571234a5c3332315c323433285c3232345c3235322e5c333530483e56475c30313444635c303035775c3231345c3031365c3030305c3333303e5c3335365c3331375c3232305c3233335c333035575c303232345c3235355c303332325c3231314a5c3234325c3335365c3230345c3230335c33343564705c333034463057785c3330305c3334305c3031355c3230335c3335365c3335345c3337313c5c3233322f5c32313236685c323431574f5c3233355c3232345c333534705c3235345c303231436d5c3336325c3337316f5c3333355c3231345c3032315c3236335c3230315c3337345c323630365c333133635c333631374d25524b5b5c3233305c3332315c323132385c333134695c3230335c3236375c3331335c3334355c3236305c3230335c303134365c3033345c3031375c3334355c3230315c3236305c3337325c3330352f5c3334362e3c4d5c323234495c333331575f735f5c3234315c3335325c323233785c3235325c333432465c3232355c323433465129545d5c3332305c3232307c5c3235345c3231365c3033305c3231305c3330365c3031325c3335375c3033305c3033345c3030315c3236307d5c3333355c323337245c3330335c3330355c3236335c3237345c323232347e6c455c3333317c5c3234365c3336325c32363042715c3230307e415c3230325c3031332e3a63605c3334306c5c303333383d275c3330345c3337323e5c3234325c3032352d5c3335375c3032345c323236785c3331325c333035344236603c5c3236315c3237305c3231372c615c3230365c333232715c333330675c3232305c3030375c3331315c3235375c3032344a5c3231325c3030325c3231315c3033315c3031335c33303654345c303333775c3030315c3334355c3031355c3331355c3231305c333730615c3231365c3233375e465c3333375c323233652525785c3236335c3333375c3234315c3231305c3234335c3231315c3230373d5c3031315c323531475c3331315c3333375c3336323b3b5f5c3033313a5c5c432469315c3337375c3030305c3232365c3235305c323232285c3031325c3030305c3331315c3030315c3230365c3330315c323134663e383f5c3237335c3033305c3330365c3332355c3333315c333330786f5c3330355c333631455c32303545765c3231315c3236315c323731365c3335355c3031305c3330345c3137375c3032335c3030355c3330375c3031335c3033315c333037205c3030315c3231365c3231335c3330345e3b5c3032346b5c3033325c3230355123465c3331375c3033335c30303568365c3230365c3030335c3331325c3030315c3233305c3031305c333730615c3231365c3233355c3237315c3334346d5c3337312c5c3333335c5c5c3331305c3231365c3031365c3337315c3234345c3030345c3030303c5c3331305c3331305c3333345c30313040595c32373776305c333033275c3231375c3235374c7c5c3236355c3236315c32373257675c3332365e5c3033315c3336315c3234345c3033335c3334325c303135245c333134235f5c3232355c3334345c3231305c3236325c323036425c3031365c3031302a395c3337335c3231335c3230327a5c3330375c3231375c3232345c323530685c33373553445c3332345c3032325c3334315c3233345c3236335c3331315c3334375c3032335c3336335c3234365c33303072705c3231315c3237315c323130415c3230335c323235235c323337465c3331305c3033334a5c3234375c3330375c3033365c3032315c3336315c303231595c3234315c3232315c3030355c3330375c3232325c3234305c3030305f5c3235325c323537276b5c3032325c3234336f5c3331305c3234307c5c3333355c3232335c3233355c3234305c3030335c3033375c323735783356645c3231325c3333355c3030305c3233315c3230346a5c3234344b2c636e5c3337365f2e365c3235365c3031315c3031325c3031315c3331363e5c3334373b705c3235355c3033335c3237355c3230345c3332355c323137685c3234325c323531695c3332376f34485c3232325c3235335c3231315c3030325c3231375c3233315c3232355c3237366f5c32323549245c323234505c3031365b5c3234363b5c3033365c3030365c3031305c3032376a5c3231315c3031325c3235357b7a5c323636515c3335366e5c3030305c33303166605c33333355775c30303049205c303230305c303136795c3336343d5c3030302458275c303033265c323736605c3337305c3331315c3337335e784b5c3330315c303237725c3335313a5c5c5c3332375c303336235c3332345c3230315c333337215c3236332122475c3031305c323030795c3232326c5c30303378205c33363037605c3231347c5c3235345c3030375c3232375c3233345c333532465c3233325c3237345c3233355c3231362c56375c3031355c3230315c3230375c3236345c3330345c33313545795c3337365c3233355f5c3331305c3336345c3033375c303333785c32353364443e5c3335305c3232305c3231375c3333365c33313124405c3032335c3337375c3030302c5c333337775c333130385c3331325c3030335c323336315c323637275c3030345c3030315c3033375c3231325c3337305c3232375c3330355c3235345c3331352e5c333033285c323637475c3331325c3235345c3235305c333130375c3030305c333030725c3032373f7a335c3230315c3233345c3230335c32333643735c3032375c323132785c3233335c3336365c3236315c3332345c3336355c3336375c3232335c3335345c3333325c30323456313b795c3231305c3237367b5c3032325c303036735c3232335c3231305c3332345c3030365c3033355c3230365c303036315c3232305c3030315c3030305c3234375c303233735c3336315c3232325c3336365c3335366f335c333733365c3032305c3033305c3335375c3032315c3233345c3230353c5c3230335c3237305c3231355c323033695c3030375c3234325c3336315c3333375c3337365c3030335c3331335c3336355c323732565c3332315c323337395c3337365c323637655c3033375c3336335c3336315c3337375c3030305c333430325c3337375c303030235c3333316f5c32373455345c32323132465c3236325c303231315c303031515c3334335c33343163245c3030325c303136235c3334305c3230305c3331315c3231365c3233305c3336325c333037405c3230305c3234355c3032335c3334322b5c3232365c3331365c3032345c3232305c3335325c3236315c3031355c333231305c3333355c3033315c3333335c3336375c3237364e5c3031305c3333355c3330303d365c303136465c3333375c3232375c333037475c3330353b5c323632785c3236315c3231355c3330335c3236325c3331315c323131315c3336336d5c3333315c333633375c3335365c3330365c3033335c3334355c3033305c3033375e5c3233305c3033335c3032323f5c323132374a5c3030325c3234355c323034655c303131475c3031325c3334305c303030765c3230345c3334355c3236315c3033305c3330335c3031355c3234335c3030335c3335335c3332335c303033625c3337325c3333352e5c3334335c3337375c3030305b5c3236325c3231375c3337315c3337325c3337375c3030305c3336305c3032375c333736475c3236315c3031375c3032305c3333345c3334335c3031325c323534555c333235615c3033335c3234326c5c323634676f5c3333365c333132755c3033335c3237305c3030375c3234365c3330315c3331305c3333335c3336325c3230335c33303437385c3330325c3235335c3032357558465c3335305c3233332d5c3033315c3333335c3336375c3236325c323335465c3335365c3030315c3335315c32363072365c3337345c3237363b5c3033375c3330355c3033335c3234355c303031525c333032325c3230345c3234335c323035705c3030303b42725c3333305c323134615c3230365c3332315c3230315c3336355c3335315c3230315c3236305c3231375c3334325c3231355c3332325c3230305c323531615c30333142515c3330325c3237305c3030305c3033355c323431396c46305c333033685c3330305c3337325c3336345c3330305c3333307d6e5c3231375c3137375c3335335c3337325c3337365c3237335c3033375c33353376515c3337375c3030303f5f5c3337365c3030325c3337375c3030305c3331305c333636215c3334325c3033335c32333461555c3231325c3237325c32353423744d5c3232365c3231345c3335355c3337335c3333314e5c323433775c3030305c3336345c333330395c3033337e50785c3230365c3334375c30333055625c3235365c3235335c3031305c3333355c303233655c3234333b7e5c333636535c3235305c3333355c3330303d365c303136465c3333375c3232375c333037635c3337305c323433745c3234302a5846505c323234705c3235365c3030305c303037684e5b5c3032315c323134305c333332303e5c3237353036595c3332327e225d5c3333375c3333375c3333325c3333315c333035615c3033315c3032335c3331335c30333055605c303036715c3236306e6f5c3333355c323134305c33333230385c3335375c3332335c30303363585c3235325b275c3337355c3137375f5c3332376b5c3230375c3032355c33343535245c3234315c3033325c3231365c3335355c3333317b5c3235375c3235375c3331305c3336355c3232315c3334325c3033335c32333461555c3231307558465c3335305c3233332d5c3033315c3333335c3336375c3236325c323335465c3335365c3030315c3335315c32363072365c3337345c3237355c3234375c3230315c3236355c3033312f5c3335362d5c3236375c32333124405c3336315c3030355c333134672b5c33313138236f5c303334285c3335335c3332336a5c333630365c3230365c3231375c3331355c3235355c3335355c3230375c3031305c3230315c3233314b235c32303124415c3030335c3030355c3032317c5c3331355c3337335c3236315c3230365c3033305c3334307d7a635c3334345c3336355f5c303032695c3231355c3031325b795c3232314b245c3335315c3236355d5c3233315c303235482b295c3337315c3233375c3031315c333137435c3337305c3230315c3230335c3336325c3334362e5c3237365c3236363e5c3330335c3331305c3336375c3237375c3230375c3232315c3233315c3331355c3235335c323430795c3230325c323434455c3333355c3234325c3330335c3137375c3235346e5c5c79635c3030375c3234315c3335375c3231345c3031365c3030365c3333355c3332317a5c3235355c3237315c3333356f5c3032315c3333345c3335375c3232355c303337345c3231335c3236355c3231375c303335485c3330305c3330315c3336365c3330305c333732575c3233375c3337305c3032374a5c30303550792c5c323233455c333131325c3230305c3033375c3031332f473b304f5c3031355c333330723839515c3334357a5c3032346a5235525c333436425c3030305c3030355c3333335c3033316f735c3231345c3031375c3331325c3235315c3032305c3330375145345c3331305c3030345c3231325c3233345c3334345c323032735c3236345c3334335c323134775c3335303a5c3336345c3337325c3337325c303332625c303335552e35285c3334305c32303165215c3230325c3232305c3033305c3233315c3032315c3232342a5c3334345c303032585c3334335c3334355c333030395c3330315c333037435c3233345c303030485c3330315c333237755c333631655c303132235c303331242a5c3030335c3031355c3332315c3032325c3330375c303031645c3031365c33353050635c3335365c32373742395c3030375c3232315c323032635c3336335c3137375c3032335c3337305c3236322b7b5c3137372a5c3030365c303036223e795c3031325c3233355c323031335c3236355c3236377c5c3233305c3033305c30333358745c3337335c3234305c3337345c32343154445c3030315c3333305c3335323e2f5c333733355c3237345c3231345c3032355c3332355c3330335c3030366f5c323634435c3336325c3237345c323132305c3237313e585c333437742d5c3331375e5c3333372f5c3337345c3236325c3336335c3331354b5c333037715c32363432445c3235365c3336315c3232365c3333335c3237312e5c3032342a5c323534645c3233345c33343479635c303330525c3237305c3335305c3030375c3232335c333330275c3335365c3337345c3332335c5c5c3336315c333732695c3332365c3231365c33363737225c3030345c3231375c3033375c3336315c3337305c323333505c3237325c3336345c33313128315c333633465c3333355c3230315c3334375c3236313f5c3237325c3336325c3231355b5c333433565c32313421785c3334315c3237335c323236525c333734797e5657664e475c3337325c323630325c303031405c3030375c3033345c3330363a6d5d5c3233314a5c323434615c323733385c3336315c3033305c3333342e5c3032335c3337355c3334325c323534635c3335325c3332325c3337345c333137675c3237375c3336315c3332315c3236375c3236352d5c3231315c3234325c3232315c303031405d4e5c333236705c3137375c323133283a5c3233305c3334345c3033355c3237325c3336363b5c3237345c3237365f535c3336315c32333037285c3236315c3337375c3030305c323434725c3332325c32333146545c32363374215c323333683d563230415c33343323695c303132235c3336305c3237335c3231375c323134365c333532535c3335345c33323657535c3030305c323734795c333434475c3237347c5c323731665c3330325c323334305c3334375c3030335c3231345c3337375c3030305c33353039475c3334325c3237345c3331344e5c3333353b7076493f7a5c3334335c3334362b5c3236335c3334366f5c3333355c303134375c3331335c3330305c3337325c3336345c3330305c3333315c3231335c333035515c3231375c3333323c395c3336314e4f4d5c3336325c3237325c333337725c3232335c3337352c7b5c3230345c3237362f5c3232315c3332315c303134265c333436225c33373064255c3030375c333132335c3330305c333030415c3236345c323030635c3330374c79605c3334306c5d5c3232346e3c5371335c33313263465c30313131545c3031325c3336305c3033345c333731445c3231345c30303622315c3231355c3237335c3337305c3033305c3030306c5c30333777675c3331315c3334325c3332315c333734515c323732505c3032352c23284a3a5c3235335c3230305c3030315c3333325c3032335c3232365c333034635c303134365c3231345c3031375c3235374c5c3031355c323236745c3233375c3231305c323237775c3336375c3336365c323636715846445c3336325c3330365c303235585c3030315c3233346c5c3033335c3233335c333637635c303134365c3231345c3031363b5c3336345c3330305c3333312b5c303237495c3335317328715e53524a5c3032315c3235305c3333336e5c3331335c3333355c3137375c3334347a5c3332315c3336315c3033355c3332335c3334375c303132487558465c3335305c3233306e5c3231345c3335355c3337335c333337275c3030346e5c3334305c3033365c3233335c303037236f5c3331335c3332375c3337305c303237525c3232365c3336325c3335325c333330485c3332325c3331315c3033375c3233315c3032325c3330365c303332335c3232315c3332355c3237366f5c3232345c3232315c3330325c3031375c3237355c333233625c333630365c3230365c3231375c333136615c323031545c303035505c3335345c3230355c333433655c3031375c3031365c3332305c333030795f337e5c3335375c3230365c3033305c3334307d795c3033305c3337313d4b5c3330305a7b465c3236365c3331365c3336315c333131335c3030355c3231354c5c323333545c303230445c3234375c33343670235c3334347e5c3233315c3033315c3033305c3333304c5d685c3337325c3336365c3233365c333437515c3336315c3030375c3334305c3234345c3033375c3033337c255c3030355c323634535c3033305c3336355c3333353c245c3333326d5c3334315c323133635c3234345c3230345c323232524f5c323230705c333733545c323334725c323730535c3231375c323233295c3331357c2f5c3337355c3234325c3336355f5c3230323a5c3230375c333734215c3137375c303231745c3335335c3237335c3031335c3233305c3030365c3333305c3335365c3234365c3030375c3331325c3232353f5c3230355c333736585c3330365c3031315c3331305c3337315c3237315c3033305c3033305c3330305c3030305c3031305c3337365c3231335c3336305c3032365c3232325c3335302d5c3330335c333035235c333334205c3030324675542b5c323636435c3232365c3137375c3232335c3233365c323034635c3332345c3031345c3033345c3235375c3335365c3237323f5c3033305c333734355c3336305c3333375c3330345c30313525745c3337375c3030305c30323169565c3333325c3236345c3031325c3334324d5c3332375c30323129625c3334305c3030315c3237332070485c30303064605c3231345c303134605c3230315c3231345c323335375c3331355c3331375c3032375c3235315c3334336270555c3033355f5c3235345c333431275c3331333d5c3233355c3332355c3334332e5c3332375a3b5c3235365c3231353f5c3237345c3336325f5c3230375c3337325c3237375c3330325d2b5c3330343a5c3233375c323132745c3233355c3231315c3235346a4a255c3237345c32333127325c3031315c303130405c3333345c3230335c3230355c5c5c3033305c3336325c3030305c30303074385c303333315c3033365c3235375c3330346f5c3333326f5c3330305c3237365c3033345c3332325c333537205c3237355c3237345c3230325c3336343a3a2c315c3236315c3232315c3233315c3230315c3030305c3030325c3235335c3331325c3233345c32303247235c3234305c3334345c3033345c3335355c3334375c3336352f5c333330375c3334315c3231355c3335345c323135245c3032315c33353276445c3236365c3337355c3232315c3333345c323036425c33333463215c3232345c3233345c3031355c3237355c3231303c5c3336355c3033305c3033305c3333305c3336305c3237375c3335345f5c3336305c3237335c3330335c3032335c3231315c3330365c3231372e5c323531302a5c3333335c333635297c5c333230485c33303725705c3032373c755c3330375c3033315c3334335c3033305c303330575c3235335c323632497c5c3337375c3030305c333430235c3232323f5c333332715e5c3331325c3232355c303332705c3333375e665c3332355c3333375e555c3032355c3332375d5c3332355c3337335c3233372f5c3337342f5c333730372f5c3330375c3231375c3032354b3e5c3232355c3234325c3333345c333730575c3334315c3236335c3333355c3235355c3331345c3336365c3235372c5c3231362e5c3233345c3033342b5c3030355c33333230415c3334335c3230305c3030305c3030305c333632365c3337345c3233375c3234307a5c3030365c323031635c3334315c323335265c3333374e5c3332335c3234304b7b585c3032342a5c3234325c3030303a5c303134765c3336365c3030335c3335315c3230305c3030375c3030325c3234375c3332335c3236345c333330345c323533545c3236375c323637405c3231305c323430765c3030333c5c3030315c3333335c3231365c3230305c3030305c3030375c3030305c3030305c3030305c3030305c303031565c3235325c3235315c333233545c3332315c3332355c3232365c3334355c3232345c3336325c3335303e5d652d5c3333355c3232325e5c3231312d5c303232577648285c3234325c3231325c3333305c3336365c3030325c323132285c3234305c3030325c3234335c3237305c3237305c3231325c3332325c333336495c3334375c323231215c323036252e5c333632485c33303155545c3031345c323232495c3335305c3030305c3235312b5c3334335c3333375c3333335c3335375c3334335c3031355c3332365c3231315c3234365c3335315c3337365c3030335c333233265c3232325c3333355c3236355c3031305c3330355c3333365c32343334445c323036305c3335365c3333335c3033345d5c303136555c323130625c333335305c30323076275c303331555c3235305c323531415c3331315c3233365e675c323330535c333133305c3236335c3330345c3332345c3335315c3236325c3335365c333732235c3231345c3337355c3234333f6d7b5c3337357e5c3336325c333433415c3337305c313737773e5c3233375c3234335c323436625c323337585c32313559275c323731275c3030335c333637595c5c5c3234325c3137375c3236365c3031306f5c323437355c333632225c3235335c3032372f316949205c33313059735c3232375c333731707e5c3335305c3331374c5c3335365c3335355c3337307c5c3235315c3033344b5c3033315c3331305c32313446415c3030305c3232344f5c3237335c3336377e555c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334372a555c32323557793f5c3335335c3337325c3337365c3237335c3337375c3030303b665c3033315c32323627335c3235345c33353362257e5c3331335c3234325c3336325f5c3332355c3333375c333436475c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c323434716d5c3334355c3336325c3334335c3231355c3337315c5c5c3334355c3337365c5c5c3033365c303230675c3234375e5c3333375c3230375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3334335c3337355c3137375f5c3332376f5c3233375c3233315c3337355c3137375f5c3332375c3337345c303232385c3236365c3336325c333731715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435235c3231336f2f5c3232375c3033346f5c3331325c3334372f5c3336325c3334305c3336305c3230333d3a5c3336365c3337343e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c3337365c3237375c3235375c3335335c3236375c3331345c3337365c3237375c3235375c3335335c3337365c3031315c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331325c3137375f5c3332375c3336355c3333335c3334365c3137375f5c3332375c3336355c3337375c3030305c3030345c3231362d5c3237345c3237365c5c715c3237372b5c3233345c3237375c3331335c3230335c3330325c3031345c3336345c3335335c3333335c3336305c3337317b5c3337375c3030305c3230325c3333365c3033335c323333565c3336315c3030355c3332355c333031505c3336305c3333315c3333335c32333166675c5c5c323137335c3031335c3236375c303330415c3237305c333431585c3334375c3236365c3031315c33343029295c333030475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337325c3333335c333636385c333730765c3332375c3033365c3032305c3332365c3236355c3330335c3032345c3031306e6e5c3332325c303035595c3032345c3030305c303034485c3033332a703e5d5c3330375c303331385c3337335c3230345c333634465c3333315c3332375c3230345c3231325c323235555c3334355c3337355c3137375f5c3332355c3337365c3235335c323036287d63365c3234345c3233365c3332315c3237345c3237365c3334355c3234375c3334336f5c33353376695c3237365c3030335c3232312f565c3333355c3233375c3331355c3033345c3030325c3231315c303330525c3331355c3231355c3235325c333337705c3030325c3330305c3330355c333233235c3033345c3230335c323637615c3336325c333735635c3330305c3337365c3033315c3337335c3031365c303231335c33303248725c3334315c3230315c3330315570315c3334355c3230335c3330365c3031302d5c333037415c3237335c3033305c3330347d5c3233355c3237375c3230303f7c5c3235305c3236365c3236365c3331365c3330335c333435445c323135765c3236365c3334315c3330325c3336355e30634e5c303136315c3236375c3233346c7d5c323335675c3230375c333734305c3231332a395c323636585c32343249365c3234305c3231362d5c3234315c3030305c3232305c32313429585c3330365c3332325c3030335c3337325c3031355c3237337b5c3032355c3337355c3331375c333231585c3337365c3231305c323737735c3234325c333630755c3230315c3236365c323635435c323236755c3231345c3331315c3033365c333531315c3237347d5c3331342e765c303032705c3032375c3033355c3137375c3230345c3030325c3030315c303333535c3234355c3235325a765c3233345c3232365121285c3230326d5c3234305c3032325c3235325c3237372f5c3331325c3235324021575c3231375c323230765c3335343a5c3030305c3030305c3237334c5c3232325c3233365c3236315c3235335c3333315c3335305c303332555c3334365c3234355c3235305c5c255c3235355c3231355c3234344d3c5c3336335c333130705c3236315c3234325c323032595c3231375c3332305c3030335f5c3232375c3237375c3236345f5c3335355c3030375c3235325c3337346f5c333631435c3334355c3334345c3236375c3336305c3330355c3233345c3230356c5c3336345c3336305c3031365c3333345c3334346d5c3232355c3230365c3333375c3233315c3231375c5c5c3334375c3031335c3332335c323631235c3333365c3137376f5c3335375c3231344f5c3033305c3236325c3337307b5c3234365c333137222b5c3030345c3237335c3332355c323134635c3230365c3033315c3030365c3033305c3237325c3033345c3231345c3230325c3335355c3332335c303330435c3335335c3231375c3231305c3334335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337305c3233305c323734435c3232345c323335385c3237355c3031375c3330365c3237305c3237333b5c3233355a5c3331372f5c3234312b423f5c3032355c3237325c3237365c3333365c3231335c3336335c333634415c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3334365c3137375f5c3332375c3336355c3333335c3334375c3337315c3234375c3336355c3337355c3137375f5c333630485c3334325c3333335c3331335c3334355c3330375c3033335c3336325c3237315c3331335c3337345c3237303c205c3331374e5c3237355c3237375c3031375c3232365c3336365c3230355c3235314f5c3234305c333532305c333336444b5c323632325c3233315c3032315c3232372a5c3335355c3336325c3334333f205c3331305c3334335c333537763e5c3233305c303333685c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c333234655c3331325c3332335c3231335c3337365c3237375c3235375c3335335c3237365c3232345c3335324e5c3232345c3332354a6e5c3332325a5c3234375c3334375c3337355c3137375d5c3337355c3337375c3030304d6175636f3c40495c3030345c323336535c3032305c303234605c323334455c3230335c33303443385c3330315c3334375c323134635c3236363e4b5c303236705c3236346a5c3233335c3234325c3333345c3233315c3231377a5c3032345c3330375c3331355c3231305c32363070225c3033315c3330365c3031373c635c3033355c3236315c333632735c3137375c3031365b5c3331365c3336305c3233355c323436205c323134345c30323379655c32323572575c3334375c3231345c3334307c5c3230372b5c323134735c333036365c32313646325c32373524505c3030305c3032355c3332325c333236385c323736785c333730545c3330365c3331375c3336355f2a5c3337365c3335375c3232355c3334335c3235376d5c3234335c3232355c3330375c3331315c3336345c3232345c3334355c3331375c3030352e5c3334375c3336355c3031365c3030335c3032335c3336355c333134252c435f5c3032324d5c3337325c3236355c3235315c3335345c3233375c3031375a3b685c3334335c3031345c3330315c33303156556542775c303233265c3030315c3033372e795c3333335c3332375c3231365c3032345c3334345c3236365c333334455c333634775c3330335c3237355c3331345c3030365c3335313c5c3335355c323631325c323131307040705c3234305c3231345c323530385c3330325c3230303a705c3237305c3331336d5c3333335c3033375c3331345c3337365c3030375c3237326f5c3333346d615c3032345c3231364160215c333030605c3332325c3336325c3032375c3031315c3230307e435c323334764e5c323734662f5c3234333c5c3032313b5c3235325c3330305c333032445c3231355c323434635c3233355c323231637e645c333434285c3031315c333036765c3233365c3333355c3032305c333632765c3337365c333437655c333436765c3033365c323131455c303234555c303130285c3234325c3237305c3235375c3231335c3137375c3032365c3236342f5c3230337e5c3032325c3233375c5c5c33323726385c3030375c3331335c3236365c3236345c3231335c3233316e653d5c3032315c3030375c3336333d5c3030305c33313135325c3232325c3231325c323733325c323533565c303234205c33353255765c3231325c3332355c323636585c3337305c3230355c3334335c3233355c3033335c3330305c3233323c5c3233325c3235365c3237317e5c3233327e5c3233356e41765c323330635c333134705c3331305c333031505c3032343b5c3333335c3030315c3236305c3032345c3334375c3230335c3231365c3230355c3232335c3334302f5c3231343f5c3236355c3232365c3236335c3334325c3237335c3237335c3231353b5c3330335c303135265c3232355c32343221315c3231335c3232325c3230335c333535325c3032335c33303065215c3030365c3330355c333332405c33373170465c3332315c3331305c3030302a795c3235375c3330355c3235375c3231345a5c3337375c3030305c3330365c3031375c303230365c3234335c323533385c3236365c3236355c3231305c3335355c3236365c3332335c333535415c3032305a5c3235375c3030302a5c3031355c323737375c3030305c3030325c3334375c3232325c303234745c3031325c3030325c333630515c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317c4a5c3337305c323637515c3336325c3330315c3333317e675c3334325c3233315c3332375c30323662315c3231355c3332315c3330315c3236375c3031327d5c3337365c3332345c3237367d5c3032375c3232325c3332375c323737615c3334345c3331312c5c323135255c3330335c3237345c3335345c3330345c3033315c3033315c3330365c3334325f5c3031335c3230335c3233355c323433774f5c3237355c3333335c3336305c333731595c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323736775c3336355c3337355c3137375d5c3237365c3137375c3030305c3333336d5c3236375c3337355c3137375f5c3332375c3233315c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331325c3137375f5c3332375c3336355c3333335c3334365c3237375c3235375c3335335c3337325c3337375c3030305c323032475c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c323434716d5c3334355c3336325c3334335c3231355c3337315c5c5c3334355c3337365c5c5c3033365c303230675c3234375e5c3333375c3230375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3233375c3332375c3336355c333735765c3337315c3233375c3332375c3336355c3337355c3137375c333031235c3231336f2f5c3232375c3033346f5c3331325c3334372f5c3336325c3334305c3336305c3230333d3a5c3336365c3337343e52385c3236365c3336325c333731715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462335c3232305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3233375c3332375c3336355c333735765c3337315c3233375c3332375c3336355c3337355c3137375c3330315c3336363f5c3230335c3337365c3032375c3237305c3137375c3031345c3333345f395c3232355c333236595c3332355c3231347e5e5c3334356d5c3234305c3033355c3337315c3333315c3230335c3231372d5c3237315c3334335c3234315c3330375c3333355c3337317d5c3031335c3330325c333332465c3333335c3233305c3330345c3232325c3030305c3031325c3032355c323232305c323130467c5c3235346e5c3331365c3330303e505c323335495e5c323735545c303030535c3237365c333730555c3336305c3234375c3335343f5c3031325c32373430265c3236375c323136612d5c3233325c33333634715c3235315c333032795c3237317c5c3030325c3032335c3030375c3031305c3235365c3031315c333130235c3030307050797b7a675c3230315c3330315c323735465c333632625c3031355c3032335c303237635c3031327c5c3333345c3031355c3333345c3033355c3234335c3234365b2c3a605c3232305c3030375c333132225c3337326a305c3334345c3234365c3234325c3137374c5c3334345c3236345c3033365c3033332e5c3234314d5c3336345c3231326f5c3332355c3335335c3337315c3236335c3334373f5c3333326b5051775c32343069585c3031345c32323047255c3331335c333431385c3331335c3337316a5c3233345c3032345c3030375c33343531305c3335345c3030363a2e365c3234375c3230365c3330375c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c3237365c3233375c333733475d5c3330373f5c3330355c3337356a5c3333365c3032305c3234322d385c333037625c303332285c3236365c333535285c3235325c303331405c3333335c3233346e5c333130395c3334346d5c3330375c3033305c3337317c5c333032385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3230335c3231305c3232373559335c3336305c5c5c3337375c3030305c3032315c3336355c3233345c3331365c323735455c323637355c3232375c3331334f5c3332335c3337325c333532475c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c323434716d5c3334355c3336325c3334335c3231355c3337315c5c5c3334355c3337365c5c5c3033365c303230675c3234375e5c3333375c3230375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3336335c3337375c3030305f5c3332375c3336355c3333335c3334375c3334305c3137375f5c3332375c3336355c3337375c3030305c3030345c3231362d5c3237345c3237365c5c715c3237372b5c3233345c3237375c3331335c3230335c3330325c3031345c3336345c3335335c3333335c3336305c333731485c3334325c3333335c3331335c3334355c3330375c3033335c3336325c3237315c3331335c3337345c3237303c205c3331374e5c3237355c3237375c3031375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334353f5c3235375c3335335c3337325c3335355c3336333f5c3235375c3335335c3337325c3337375c3030305c323032475c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c323434716d5c3334355c3336325c3334335c3231355c3337315c5c5c3334355c3337365c5c5c3033365c303230675c3234375e5c3333375c3230375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3233375c3332375c3336355c333735765c3337315c3233375c3332375c3336355c3337355c3137375c333031235c3231336f2f5c3232375c3033346f5c3331325c3334372f5c3336325c3334305c3336305c3230333d3a5c3336365c3337343e52385c3236365c3336325c333731715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314f5c3335335c3337325c3337365c3237337c5c3331375c3335335c3337325c3337365c3237375c3334305c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c3033372b5c3234305c3230305c3232375c3030315c3230315c3232305c3236315c3030315c3230365c3331345c3334355c3337365c5c5c3032315c3230345c3033315c3335315c3332375c3236375c3334315c3336325c323636385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f695c333630575c3330315c333232785c3331375c3334325c3232375c3230365c3336345c3231336b65775c3233325c3335355c3033315c333433415c3231375c3232355c3030307640765c3337355c3332325c3236315c3233345c323336315c3231365c3234335c3033372d4129492e5c3337375c3030305c3332375c3336355c3336323a305c3336345c323336225c323634285c33303779345c3237365c3336376f5c3335335c3337325c3237375c323733685c3333375c3031355c3334365c3236315c3236305c3236325c3236344d5c3232325c323634715c3235323236332c5c3230307c5c3235347e415c3336335c3030335c3033305c3336345c333037395c3330365c3330365c3333315c333337785c3032335c3330315c333237305c3236325c3331305c3030315c3232355c323433235c33313462335c323737635c303232485c303333415c3033305c303033245c3032315c323030575c3236335c3137375c3235325c3336355c3235305c3237365c303336635c3331315c3336325c333534613f7a355c333332365c3335365c3232317e5c3335305c5c5c3234375c3033305c3333315c303236415c3334346d5c3334345c3235365c3330365c3333315c3237355c3334315c3331375c3030355c323534765c333032365c323031365c3231375c3333355c3231345c3330345c3331355c3033305c3330336c5c333731705c3234305c3235365c3030335c3031345c323136315c3230335c333130604c5f545c323433635c3337325c3233325c303231545c3334305c3234315c3032355c3234325c3332335c333536255c333630475c3230365c3331365c3232365c333631206d5c333632455c3334355c3230375c333731325c30313059305c3031365c3030327c5c3237365c3234345c3032305c303030287a325c3232335c3032375c3234345b5c3235345c3231336f5c3032305c3232345c3335365c323234285c303136735c3233345c323334735c3331365c3030375c3336325c30333741585c3237325c3032365c3233325c3332302a5c323235445c3236375c3031335c3232324c505c323534675c3232315c3033315c3330365c303134635c3235365c3332325c3031315c3334335c3233365c3330305c333430265c3336355141455c303234505c303031455c303234505c303031455c3032355c3233375c3334325c303335725c3332375c3330333a5c3031365c3234355c3235345f314b2d3e5c3333324b5c3235315c333331464844525c333134405c3337325c303033495c3237336a29355c3032345c3334345c333636475c3233325c3337365c3332305c3237375c3236342e5c3232315c333630275c3330335c3231332c5c3235325c3237325c3230365c323737765c3031305c3236305c333233416f5c3233375c3232305c3031335c3237315c3030305c333535415c3233375c3330375c3033305c3033355c3331305c3337345c3331375c3336315c3335375c3330343f5c3032305c3337344d5c3336315c3030345c3333325c3330375c323131755c303131755c3031335c3231315c3033333e5b5c3031375c333335424e5c3333355c3235335c3033325c3335355c333431463a5c3231374e7a716b5c3334325c3236375c3330346d435c3334325c3237375c3231375c3236355f5c3032336a3b5c3232324b5c323331715c303234435c3334365c33373334595c30333322535c3236375c3232355c3030305c3031345c3236375c3033345c3334345c3336315c3333335c3231365c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336335c3236355c3336315c3031365c3237335c3336325c3337365c3237375c3235375c3335335f5c3334375c3235345c3337333e5c3235335c32333356715c3231336a5c3232325c333331775c3336337e7d5c323733745c333633235c3231336f2f5c3232375c3033346f5c3331325c3334372f5c3336325c3334305c3336305c3230333d3a5c3336365c3337343e52385c3236365c3336325c333731715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731793f5c3235375c3335335c3337325c3335355c3336335c3337315f5c3335335c3337325c3337365c3237375c3334305c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3234375c3336355c3337355c3137375d5c323736675c3336355c3337355c3137375f5c333630485c3334325c3333335c3331335c3334355c3330375c3033335c3336325c3237315c3331335c3337345c3237303c205c3331374e5c3237355c3237375c3031375c3232345c3231362d5c3237345c3237365c5c715c3237372b5c3233345c3237375c3331335c3230335c3330325c3031345c3336345c3335335c3333335c3336305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e535c3337325c3337365c3237375c3235365c333337335c3337325c3337365c3237375c3235375c33373024715c333535397c5c3237305c3334337e573f3f5c3331335c3230335c3330325c3031345c3336345c3335335c3333335c3336305c3337317a5c3237375c3031335c3337305c3335365c333637455c323232385c3235375c3233364b5c3335335c3032305c3331335c3334365c32353328675c30313436615c3232345c3335345c3337315c3236315c3236375c323531205c3031376c5c3031355c3237345c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372e5c3232345c3335324a5c3233335c3237345f5c3336355c3337355c3137375d5c3337335c323630785c333534465c3030325c3235325c3235355c3230365c3233335c3231335c3337345c3337345c3233325c3333315c3234335c333337745c3235315c3334325c3237375c3236325c3231325c3334325c3333315c3232327b76685c3336375c303235515c3230325c3330335c3331325c3033315c3330375c323234335c3231345c303336785c3330363b635c3334345c3236316f5c3030335c323434695c3336326577475c3237354a635c3334365c3337355c3332365c3031363c5c3234315c323334605c3336335c333036315c3333335c303337275c323135782f5c3330346d5c3334315c32333541335c3032325c3337355c323132595c3032304e5c323431335c3334355c3336325c3233345c3234375c3331315c3331305c333731464f5c323636385c333030295c3335345c3236365c3336315c3235335c3330345c3232325c3330356d5c3033346a5c3331355c3033315c303333505c3231355c3230305c3337315c5c2e635c3331315c5c5c3031365c3234375c3234365c3332315c3331325c3334335c3334345c3336375c32353056555c3234317e5c3234375c3336345c303136455c323335535c333136705c3337345c3336365c3236345c3334335c3336312f5c333235793f5c3336335c3336352e69725c3331375c3030335c3231315c303333382b5c323632405c3331315c3233355c3331345c3331305c3230305c30333479633d5c3337366e315c3335355c323134275c323635785c303337585c3031315c3033305d5c3334355c3232355c333332405c32343760605c3334315c323330226079605c3336305c32353270785c3030305c3031363e5c3335315c3032315c333730655c3237345b305c3336315c3333335c3235345c303337325c3031375c3333355c3234315c3030355c3030315c3032315c3031355c3235335c3337335c3236304a5c333430605c3233365c33333347235c303337275c3234377c3e795c30333160495c30323562385c323137315c3232345c3333345c3235347c5c3330324e5c3330335c3334355c3336355c3337317a5c323336715c3033376c663e5c3232345c333732235c3335315c3033315c333635675c323032752f325c3030325c323731775c3231345c3236335c3236365c3334355c5c5c3230365c3030355c333032275c30303235385c303031485c3030345c3334305c303030385c333431485c3231375c3235375c323537375c3336303d5c3332335c3032355c3230335c3031345c323631485c333434335c3030315c3032365c3030335c3030365c3232335c3232305c323434265c3030375c333334395c333037643c5c3336305c3031345c5c5c3332375c3335356f5c3336317e4f5c3230345c3237375c3031325c3335365c3033325c33303259215c3332365c333635675c3337335c3031355c3233345c3232305c3232325c3033365c3033345c3231375c3233365040385c3333323a5c3033365c3330355c3230315c3335355c323332535c3233325c3230345c5c5c333434705c3334325c333631545c33363054275c3231305c3235335c3336305c3330355f5c3337325c3336337b235c3330305c3337375c3030306c3f5c3333325c3232365d4a5c3337325c3336335c3330305c3237365c3032325c3237335c3033375c3333315c323231665c303135565c3337365c303230495c3233324c5c3230315c3334345c3234315c3333335c333637575c3337305c3233305c3033365c3237315c3033355c3030315c3235375c3231355c3334335c323137695c3331345c323331715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435765c3333375c333336345c323035765c32373123732a5c3334345c323032765c3336303e5e545c3334335c3232335c3335355c3333335c3033372b635c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337345c3332354a5c3231365c3235345c3237315c3233315c3337345c3333355c32333166355c3336334a5c3335365c323735775c3335305c323732255c3333315c3137375a5c323034716d5c3334355c3336325c3334335c3231355c3337315c5c5c3334355c3337365c5c5c3033365c303230675c3234375e5c3333375c3230375c333132475c3032365c3333365f2e385c3333375c3232355c3331365f5c3334355c3330315c3334315c3030367a755c3335355c3337307c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372e5f5c3332375c3336355c333735765c3337315c3337315c3137375c3332375c3336355c3337355c3137375c333031235c3231336f2f5c3232375c3033346f5c3331325c3334372f5c3336325c3334305c3336305c3230333d3a5c3336365c3337343e52385c3236365c3336325c333731715c3330365c3337345c323536725c3337375c3030302e5c3031375c303130335c3332335c3235376f5c3330335c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314f5c3335335c3337325c3337365c3237337c5c3331375c3335335c3337325c3337365c3237375c3334305c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3234375c3336355c3337355c3137375d5c323736675c3336355c3337355c3137375f5c333630485c3334325c3333335c3331335c3334355c3330375c3033335c3336325c3237315c3331335c3337345c3237303c205c3331374e5c3237355c3237375c3031375c3232375c3235335c3337305b5c323431495c3235335c3337305c3237365c333330615c3233345b5c3235335c5c5c3331355c3230345c3031355c33313228205c3337355c333136475c3033377b5c3236375c3236363e5e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3332315c3337375c3030305c3236315c3333375c3230314e5c323631375c323132356f25625c3231325c33333228605c3336335c303032635c3030345c3337365c3336315c323232365c3333315c3331375c3032305c32343648205c3231365c3031375c303031725c32333538685c333633555c3231375c3336355c3337355c3137375c3330335c303337435c3330335c3332343e5c3236335c3233325c3332305c3230335c3333313b5c3337375c3030305c3334303a5c3337365c3230365c3334365c3233375c3334306b5c323233725c333230447c5c333036525c303030475c323130205c3232315c3230375c3331325c3234347c5c3230335c323230623d715c323136725c303030435c3236335c3332373c5c3033335c3334315c323031665c32343235525c333031515c333337322b64705c3236325c3031363c5c3236307230416e3e5c3335305c333136305c3030347d7a785c3032375c3331315c323332455c3032315c33333365305c333030347b555c3030305c3334305c3030304a5c323134635c3331315c3030375c3232335c3232355c333037385c3031305c3333333a5c3337375c3030305c30313378452d7c5c3233345c3330315c32363523605c3235335c3236315c3031365c3032376b5c3335355c3337315c30333026545c3230305c3330335c323536315c3231365c3331345c3031315c3231335c3335312c5c313737485c3333375c3235315c3332325c333730334c5c3337332c5c303032405d5c3230326f5c323133745c3231355c3232365c3030332b5c3230315c3336375c3030374c605c3233345c3230335c3336325c32303040202a745c3336355c3233355c323436592d5c3235315022405c3335305c3234315d5c3336365c3230352a76205c3330325c3232305c3231325c30333148515c3331375c3235305c3030335c303334616f49205c3231317736485c3331305c3033372a5c3232335c3332345c3334335c3236375c3336335c333535425c3332305c3232315c3236325c333132626525735c3033315c3334305c3232315c3232325c3330305c3232325c3030305c3334305c3031365c3233345c3233345c3233365c3333305c3336345c3331315c3033344e5c3236375c33343249345c3335305c3030335c3330366372595e565c3232345c3030325c3033315c3330322e5c3333345c3231372c5c3033355c3333335c333433235c323334775c3030335c3030354f5c3232355c3231355c333631435c3334325c3234365c3232335c3334307d275c33373347585c3237355c3236375c3236335c3230335c3232355c30333669255c3231336d5c3031355c32363230235c3333375c3237337c785c3334335c3030375c3230335c3331302a4c5f5c3031335c3337345a5c3337355c3235305c3336355c3235375c3033315c3333364f6b5c3334315c3333305c3331375c3230375c323634615c3233305c333637425c3230335c333535325c3334345c3336352c5c3032375c3030305c303230795c3333335c323134735c3331305c3030305c3030345c3334375c3235355c3231305c3230355c3033355c3033365c3337355c3231375c3233375c333135735c3331345c303336535c3033375c3333373b5c3331315c3335355c3032355c3237375c3337345c3030355c3334365c333736475c3237347c585c3337305c3337375c3030305c3334315c3237375c3031305e495c3031335d5c3033335c3337335c333730585c3330366d5c3335353e675c3334315c3337305c3030345c3231305c3330325c3230355c303132765c3336335c323032315c3230305c3030305c3337335c323337325c3337305c3236375c3334335c3335365c3237355c3235375c5c5c5c2d5c3233305c3033327d5c3233345c3230376b657c5c33333149385c3334345c3236315c5c5c3033345c333630495c3030305c3030315c323635715c3230305c3231335c3236375c3331335c3230325c3337345c333535215d5c323536485c3333345c3331325c323731205c3233355c3237345c3030335c3236375c323235385c3334345c333733765c3330375c3331325c3333305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237363d5c5c5c5c5c3335326c5c3335345c3231375c3331305c3236335c3033362c5c333134315c3332375c323135375c3335345c3334335c3333323b5c3337345c3334355c3237375c3333356f425c3331355c3332355c3336355c3333365c3234332f5c3233317d71355c333433715c3237345c333132775c3337345c3333372e5c3031305c333731795c303334755c3334305c3031375c3330335c3334355c3235355c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323734775c3237335c3237335c3137375c3332375c3336355c3337327c5c3337363a52736e52776f5c3337325c3337365c3237375c3235335c3232315c3330355c3236375c3232375c3331335c323136375c333435735c3232375c3337317078415c3233365c3233357b7e5c303337295c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3235335c3337325c3337365c3237375c3235365c333337395c3337365c3237375c3235375c3335335c3337365c3031315c3033345b797c5c3237305c3334337e57395c3137375c3232375c3030375c3230345c3033315c3335315c3332375c3236375c3334315c3336325c3336355c3233375c303133345c303131355c3231375c3032374039716c5c32313575305c3333305c3031364a5c3030355c3330315c30333727385c33303677765c3334375c3234363e5e4e385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3332325c3137375c3236315c3334375c3230305f564f5c3032336b465c3033305c3234325c3230325c3032355c3231325c33333038415c3237305c3032305c3030345c3231345c3235307c5c3237345c3334335c3032315c323437205c323032315c3233375c3334305c333132745c3334315c3234325c323435562b5c3337325c3337365c3237375c3334305c303337475c3330335c3236345c30323627355c3234315c3030365c3236344e5c3337375c3030305c3337305c3031365c3237375c3234315c323635675c3334302b5c323031706d5c3332315c323236765c303333485c3231355c3234325c3031325c3033355c3230375c3031327e5c3334305c3337315c3230315c3231335c3333336e4e405c303130767a5c3332375c3230337c2c5c3236365c323530235c3031315c323735515d5c3336332a31235c3230355c323230715c3334355c3230335c3232315c3231346e5c3334335c3335365c3231345c3334335c303030475c3333305c333333785c3030355c3237365c3332345c3332305c3330375c3031345c303232495c323230515c3030345b715c333331554e5c3330315c3333365c303235383c5c323134735c3231355c3231355c3236335c3236305c3336305c3332375c323035235c3230305c3330325c3030355c3237375c3232375c3031342c5c3032315c3030325c3234375c3333355c303032423e56585c3330315c3031345c3030335c3336335c323334636f623f735c3336345c323131585c3337365c323136373c5c3032355c3234325c3234355c3236355c3234302d5c3032302a5c323232485c323730735c3237335c3234335c323531535c3331325c30313646393d41505c3031372a5c3032353a5c3333325c3331365c3332332c5c3232365c3332345c3235305c3032312074505c3235365c333733425c3232353b5c3032306148455c3031345c323434285c3334375c3332345c3030315c323136305c323732345c3330345c30323451455c3030305c30323451455c3030305c30323451455c3030305c30323451455c3030305c3032355c3337314f5c33373353785c3231345c3337305c3234375c3334335c3336375c3231346e5c3336315c3230355c3236365c3237355c3337335c3030325c3232315c3033305c3030357c5c3232305c3236315c30323038395c3030345c323431245c3334375c3336325c3330365c3032375c333635275e5c3332355c3234315c333230344d43535c323731385c3236375c3236325c3236375c3232325c333432435c32333461514b5c3033365c3237365c3330325c3237375c303332355c3033335c333131754d525c333633505c3237315c3330315c3237325c3237315c3233315c3234365c323332444f5c333433625c3031315c3030335c3334355c3334354f735c3333335c3033355c3236315c3336325c333731585c333731695c3033305c3033375c3232375c3336315c333236212a5c303234705c3337355c3333335c313737725c3236375c333532545c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317c6b5c3337375c3030305f5c3332375c3336355c3337325c3337363f5c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3335315c3237365c3032335c3337307b5c3234365d5c333530565c323637575c303236645c333137295d5c3331355c303333325c3335355c3030345c3234305c303031404e576f535c3337365c333137515c3337345c3033335c3332325c3234352a5c3331365c3332315c3137375c3332375c3336355c333735775c333636725c3237345c3235335c3032315c3233335c3332355c3232355c3033343b574a5c3335365c3337336e5c3232375c3233375c3137375c3335335c3235375c323331475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337335c3336375c3230365c3337365c303135786e5c3336326f5c3333365c3333325c3235346c5c3032372c5c323133315c303035465c3332315c3233355c3234375c303033206d5c3033315c333136385c3335365c3234305c3032325c3233365c3330335c3334315f5c333331635c3334315c3335355c3336325c333034645c3332325c3333315c3033335c3331325c3031345c3330305c333335485c3231365c3030365c333136485c3337335c3237345c3030325c323433205c3335355c3334335c3235365c3332305c3031315e5c3235375c323531547d515c3336345c3331375c323032732f5c3334375c3230375c3333365c3337375c3030305c3337315c3033375c3335335c3336335c3337305c323032385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3336345c3237374d5c3337355c3231315c3237365c3032305c3331356d5c3031345c3331315c3234305c3331345c303131505c303333655c3336345c3333345c3032315c323634325c3336355c3030375c3337305c303130235c3030305c333632785c3033305c303031665c3231335c3336365c3033355c333730455c303131525c3237325c3030345c3334305c3230305c303036455c3335345c323433235c3334355c3033355c3233335c3237365c3333375c3332375c333331705c3337365c323433575c3237325c3032375c3337325c3232355c3233315c313737343e5c3336375c333736475c33343654712c672b5c3033305c3231345c3334345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237375c3235325c3233375c3236325c3332375c323033625c3336305c3330375c3330304f5c3030365c3333334d695c3031324f2d5c3234305c3237356c205c3334335c3331365c313737355c31373720535c3332335c3335365c3231365c3030363030625c3337355c3230375c3237365c30323142545c3235365c323031382a5c3030305c3331305c3237355c323234647c5c3234335c323633775c3333335c3337325c3337332e3d5c3331334e5c3332335c3335355c3336345c3233353e5c3333325c3330365c333232255c3230325c3332365c333332255c323036285c3232305c3030305c3235305c323132305c3234305c3030315c3330305c3030305c3031325c3335345c333033615c333435464d5c3331305c3337325c3337365c3033335c3334315c33353446535c3231305c3233356c4b4e5c3335325c3331325c3331355c3237365c3237325c3336345d5c323031745c333533445c3333335c3236365c3332365c3032355c3333335c3231346230315c3231355c3237305c3337345c323636275c3337355c3336323d5c3030353e5c3033332b7b765c3031355c3032345c3032315c333034405c3333325c303132205c3033305c3033305c3030335c3033375c3232325c3235305c3337375c3030305c3230305c3231374a5c3233325c3231325c3336345c3031375c3332305c3330365c3330375c303332435c3033325c3330375c3033325c323034455c3030315554605c3030303a5c3030302b5c3233375c3337305c3230355c3334336b5c3033375c3230373e5c3031335c3332355c333734475c3235305c3233375c3336345d3e5c3333355c323436285c3031365c303332465c3335305c3235303d5c3333315c323130515c3335366b5c3234325c3235375c3230353f6f5c3331375c32313423545c3332355c3335343c5c3030335c3234365d5c3032336b605c3330325c33353354315c3031345c333436735c3231372a235c3336325c3336325c3032354b315c3330315c3330375c3331363b5c3235375c3331335c3230356a5c3233365c3331325c303136475c3230375c323335662b2b5c3330314f5c3032315c3336365c3236365c3231375c3233337b5c3137375c3233375c3331305c333731475c3330355c323336245c3237365c3336315c3233375c323132754f5c3032306a6d5c323737515c3332346e5a5c333432795c303231735c3236355c3233305c3231375c3232357e5e535c3030305c3031345c3336365c303030745c3330375c3331335c3231375c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337315c3233335c3333375c3235375c3336355c3337355c3137375d5c3337375c3030305c3233336739545c3232335c3233345c3333355c3333335c3333375c3337325c3337365c3237375c3331345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3332325c3336305c3331365c3231315c3337355c3235375c3235355a5c3333325c3234346235795c303234485c3332315c3234375c3333345f5c323237217e5e575c3030335c3235376c765c3330375c333133455c33343058675c3232335c3032315c3231305c3231306c5c3033355c3231315c3336374f5c333132365c3231375c32323065785c3334345c3336315c323134765c3330375c3331325c3335345c3335345c323337475c3337355c3137375f5c3332355c333634745c3234365c3235312a5c333137665c3333325e5c3235325c3331355c3337366b5c3337325c333336385c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232366f5c3337355c3137375f5c3332375c3335335c3231375c3336355c3337355c3137375f5c3336307d575c333431515c3333355c3334315c3337315c303230425c3237315c3231325c3335305c3031345c3230345c3337335c3230305c3337315f2a5c3337345c3233345c3235375c333132493c635c3030335c3232315c3231345c323537635c3032345c3030305c303035745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c333731385c3033375c3230346a5c3030355c3237365c3234305c3231315c3030325c3230325c3232325c333032585c3230355c3337335c3233312a305c323737215c3331305c33303272785c3330365c3332315c3331305c333036575c3237365c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313e5c3231335c3031345c333537463a5c3233375c3332315c323734353f695c323234505c3232375c3232335f736b5c3336343d3b5c3334315c3334347e5a5c3333335c3330375c333435476e5c32343122515c3033375c3232345c3031325c3236305c3032325c3232335c3230343e5f6d5c3237357d233d315c3233305c3337365c3232325c333630335c3235375c3232336b5c3032305c3333325c3234372a5c333330685c3231315c3333345c3031345c3237375c333032765c3032315c3233375c323233395c3336344e5c3237345c3030335c3032375c3331345f5c3031365c3230365c3333315c3335355c3234334b785c3334325c3330315c3230355c303335575c3232355e4b617e4e5c3230335c3030335c3231375c333636495c3330305c3330365c3335305c3337365c3232305c333730725c3230353c5c3233305c3331355c323734565c33303024285c303230465c3033315b5c3032325c3032335c3230343e5f6d5c3237354f643d315c3233305c3337325c3232315c3336345c3236325c3332345c3336355c3231322a3b745c3336325c3235355c3334324f2d225c3333325c32343079715c3337355c3332355c3334335c3234305c333430703e5c3230325c3234345c323532245c3331325c333631575c3231315c3336345c3337375c3030305c3030367877505c3332365c333635595c3237345c3231353e5c33303623345c33323263245c3030315c3335303b5c3232335c3332335c3336315c3235375c3331325c3235375c3231365c3137375c3033315c3236356f5c3231355c333336375c3233335a5c3237375c3333356f655c303136605c3236315c3236334c5c3232316b5c303236415c3031323e5f5c3233305c323637575c313737515c333330285c3031335c333634775c3337345c3032345c3030375c3334325c3335345c3330365c3335334e5c3337305c3137375c3234375c33313524702a5c3234355c3335365c3235305c3332315c3232335c3336335c3236313f5c3237315c3231305c323134725c3030365c3031335c3233365c3333345c3234315c333532323e2a5c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c333432632b5c3336334b5c3333315c3234375c3234325c3337365c3237375c3031375c3331345c333734575c3231335c3336335c323131622b5c333735425c3232335c333637215c3237375c3233345c3237337a2f5c3331375c3334345c3032315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3233315c3137375c3335335c3337325c3337365c3237375f5c3331365c3137375c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3331375c3234375c3335315c3236325c3333365d475c3030355c3235355c323731695c3333355c3230325c3230355c32303532415c3330325c3337345c3235335c3336325c3336325c3237305c3033345c3233365c333030765c3330375c3331335c3335323e5c3031355c3337305969685c333533715c323531425c3232335c3331325c3030375c3337325c3234305c3031325c32343265535c3030305c3030325c32313258765c3335335c33373420635c3236325c333634525c3234333a5c3333375c3031365c3333375c3332375c3336355c3337356b5c3335365c33343579362f375c32323358755c3335365c3235355c3334345c3336365f5c3334375c3335305c3235375c3337367e635c323436685c3336375a5c3231355c3330325c33303363632c5c3336335c3232325c3030365c333133485c3031335c3236305c3334307c5c3235325c303032725c3237305e4f6c765c3330375c3331335c3332335c3333315c3337345c3032365c3336315c3334345c3336315c3031315c3235355c3337345c3031335c3334325c3032365c3231345c3232303c5c333130345c3231315c3333305c3030335c3336325c3231355c323532445c5c5c3235375c303330275c3236363b635c3334355c3337335c3032335c3334315c3333355c3235355c3230365c3233376a5c3236365c3236363a7d5c3235355c323534285c3235345c3331305c3332365c3331325c3030325c323034245c3030305c3030365c3032317a5c3335355c3331315c333136395c3033305c3030335c3334352b5c3033375c3332315c3337365c3031355c3237325c323031215c3333305c3236365c3332315c3030304b3a5c3331335c3030325c3335365c303333595c3232345c303134615c303036335c3231345c3233345c3334305c3031355c3237305c3030306d655c3231375c3332305c3231365c3030374f7a475c333530345c3237305c3032365c3233372f5c3335375c3235335c3237335c3337312f5c3336336c5c3337345c3232345c3332355c3337345c3031375c3235365c333730585c333437555c333230355c3031355c3033375c3232305c3234345c3333345c3333313c5b4f5c3030336a5c3335365c323134647c5c3234345c3032335c3333336f6c7c5c3237305c3335315c3031325c33303472235c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3337335b2449325c3232355c3232315c3032355c3332345c3336355c303134322b5c3331325c323734735c3337332d5c333734345c3336315c3335345c3031362e5c32373431695c3234365c3333355c3032315c3230355c3237355c333232635b59535c3233365c323737285c3333325c3333375c333630207b7a5c303134445c323630325c333733325c3337365c3237375c3235375c3335335c3237375c3032362b5c3230315c3235325c333035375c3230365c3235345c3233375c3232345c3232355c3237375c3032355c3137375c3331305c3337345c3234365c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3234355c3334315c3231355c3030355c3336355c3335375c303231695c3233325d5c32373279735c3333365c333335436a5c323436285c3336375c3032356764505c323532365c3231355c3331335c3332335c3233363a765c3330375c3331335c333634575c3330365c3031375c333330535c3330345c3333365c3030335c3032377a5c3234375c3230355c303334785c323233465c3231355c3236375c303130225c3231342d5c333734295c3330375c303336585c5c48305c3234305c3032325c323437774c285c303337775c3231325c3337355c3232317c5c303334755c3333375c3333325c3032375c333033504d665c3235325c3237327c5c323537793a5c3236325c3230353134515c333435405c3331325c333632375c3235327b5c3336315c3333335c3033372f5c3032375c3236325c3232346a284f5c3235375c3336355c3337355c313737575c3337305c3232375c3232345c3334325c32353063695c3334305c333631307172697a5c3234365c3335355c3234335c3333335c3337325c3337335c3337375c3030304a5b5c3330323669636d655c3033355c3236342f695c3032346b5c303330425c3232315c3234365c3330355c303032355c3330325c333431385c3337315c3032305c3231365c3031305c3335345c3030363e525c323730575c3333365c3033325c3236365c3332326c5c3335366f5c3235365c3234315c3230305b5c3333325c3231355c33363379715c3232305c3333305c33303027695c3333325c303037466f5c323330605c3031345c3033375c3237335c3336325c3337315d5c333635515c333234745b2d574c5c3233374f5c3237305c323637565c3236355c3233325c3333355c3335355d5c3032305c32323422265c30333359555c3232375c30303572315c3332305c3231365c3230335c3332325c3237365c3232355c3235352c5c3231375c33353137745c3237355c3333355c3331375c3330375c3031375c3032326a5c3230375f5c333631365c3235355c3235335c3237347e5c5c5c3236375c333237725c5c5c323731545c30333156765c3031355c323634615c3030302b5c3335327b635c3236363e5c5c5c3237305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237375c3235315c3335335c333733217c21435c3232355c333630555c3234325c3033345c3032315c3232355c323336615c3330375c3334305c3337375c3030304f5c3331307a5c3031345c3031335c333733217c20435c3232355c333630555c3234325c3033345c3032315c3232355c323336615c3230315c3332335c3236335c3337353f215c333530315c3334327d465c323537755c3337357c5c3231375c3330355c3234355c333031395c3231345c3233335c3232335c3235335c3030365c3333375c3233335c3337375c3030305c3334344f5c3331335c3031305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3332345c3336355c3337355c3232305c3237365c303230215c3331325c3337302a5c3332315c3031365c3031305c3331325c333137305c3330305c3335315c3333315c3337365c3233375c3232305c3336345c3033305c3337315c3231375c3336365c3333315c333730555c3334302f5c3230355c3033325f5c3230362d5c3237342b5c3234305a5c3335305c3337325c3230355c3336345c3336325c333131345c3232365c3335365c333537275c3232345c323031405d5c3235355c3237305c303035255c3337325c3336315c3336375c303037655c333731725c3235315c3230345c3235314e2e726a5c333337335c3331365c33313438575c3032375c323237615c3234375c3231325c323535523c5c3236315c3236365c3332375c3237365c3235365c3333355c3237345c3331375c323233235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e2b5c3337375c3030305f5c3332375c3336355c3337325c3337345f5c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f475c3334305c3031375c3031375c3330315c3235346b7e5c5c5c3332365c3235325c333630465c3234305c3331305c3032305c3032315c323637255c3032376a5c3232305c323331235c3033355c3337355c3237325c323134656e5c30323175245c3234325c3233365c3337375c3030305c3332375c3336355c3337355f5c3235375c3031315c3230355c323336375c3032315c3031343d3f5c3231324e5c3333325c3337365c3237365f5c3332375c323537395c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3335355c3336365c3033375c3031365c3336345c30303776735c323434455c3032325c3232315c3331305c3031365c3335335c3236332a5c3233372a5c3334342e475e7b605c3031365c3333305f595c3336305c3232375c3330305c3031375c3030375e5c3031355c333633786a5c303236745746314b28525c303237685c3331305e5c3031305c333030524f4c743d365c3330375c3333335c3336352a5c3233355a5c3337365c3237375c3235375c3335335c3235375c3333355c3337375c3030305c3235305c3333305c3337365c323635615c3336375c3237375c3336323e375c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336355c3031375c3337345c3032335c3335335c333031705c3335325c3337375c3030305c303235754d666b385c3234345c323133485c3236305c3337315c3033305c3330375c33303453485157615c3333323f5c3230355c3033375c3233376f6f5c3232375c3335314f5c3031357e5c3331315c3137375c3031335c3235365c3234325c3336335c3234375c333630655c3234325c3335356923212e265c3033347c5c3234315c3137375c3237335c3331365c3030315c3331374c5c3032315c3231345c3030325c3030325c3234375c3234345c3337343d5c333730395c3334305c3333375c3230354f7a5c3333365c3032345c3332306d5c333634665c3237355c3031302768595c3233305c3237305c5c5c3335355c30333731385c303033275c3234375c3236375c3234305c3330365c333634705c32323521514a4d595c3033365c323436555c333032385c3235345c303336365c323336225c3237345c3334325c3334335c3032377d2f7d365c333335773a5c3234355c3332335c3235355c3032336e5c33333358576e315c3231305c3330305c333036365c3334335c3336325c3333305c3233375c3336375c3331305c3336345c3032345c3337306c5c3235355c3335355c3333303450475c3032315c30303368285c32303060605c3031347e4a5c3234335c3337365c3030323d2a6a2b5c3332373f565c3033335c303334695c3031346b5c3033346a5c3032315c3032345c30303555515c3230305c3030305c3335305c3030305c32343751455c3030305c30323451455c3030305c30323451455c3030305c3032355c3334315c3033375c3236365c3236375c3231324f5c3230367e5c3030316a5c3336315c3234335c333731725c3335325c3232335c3330335c3234375c3234315c3033345c3233375c3233315c323637305c3030335c3033355c3332315c3033307b5c3031345c323336315c3233325c3336377a5c3337305c3235375c3337365c303132315c3334325c323230235c3336305c3137375c32303723735c3233355c3332325c3333375c3331365c3235335c323032475c333335485c3337305c333031383f5c3237355c3331315c3331305c303334775c3335325c3237345c3333305c323331725c3332315c3232315c3336335c323734455f5c3335325c33333155795c3234375c323533565c3337375c3030305c3330305c3236345c3337354f5c3231305c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3233325c3237375c3336355c3337355c3137375f5c3235375c3336335c3231375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f695c3336305c3333375c3330325c3332365c3233325c3330315c3237355c3232365c3335325c333135245c323136365c3231315c3030305c5c5c3235365c3332324a5c3230325c3032345c3230345c3331315d5c3234335c3235375c3332335c3232315c3231345c3235365c3232345c3334305c3335325c333131462f5c3137375c3335335c3337325c3337365c3235375c3335305c3334355c3337305c3033325c3237315c32323626385a2f5c3333365c3232355c3336375c333333457d775c3337365c3237375c3033362e385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3333345c3336345c3233375c3230365c3333325c3031355c3331345c333136465c3231335c3033325c3231355c3234355c323130565c3232305c3032345c3337355c3333325c3233342f5c3331325c3031315e5c3237313d5c3236365c3231365c3233305c3330325c3337335c3033375c3230343e5c303030785c3032365c333636375c3336337c335c3031335c3030305c323632655c3330345c3236325c3235332e5c3330345c3033305c3030305c3030315c3332335c3230335c3237335c3234375c3333355c33343766365c3330375c3333345c323630353b5c3234335c3335355c3033375c303033665c3031337a5c3232305c3337335c3333375c3337375c303030235c3337357e5c3137375c3032345c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337355c3332315c3336313f5c3336365c3033305c3332305c3236356f5c3031335c5c6a3e5c3030305c3230375c3337332f5a5c323635525c3331336665665c3231325c3335336a5c323536625c303336625c3334355c3033345c3334305c3231355c3333315c3333335c3232355c3330315c3031315c3233375c3333355c333734365c3336366d633c5c323231495c3030315c3236365c323332365c3336325c333434415c3033365c303332365c303333414036745c3334335c3030345c3336365c3330376c7c5c32373475294e5c3232335c3236345c3337375c3030305c3235375c3335335c3337325c3336335c3337314c5c333233285c333035655c3032355c3032353c425c333337665c3236365c3137375c3332375c3233375c3337343c715c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372e375c3337365c3237375c3235375c3335335c3336355c3336315c3137375c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336355c3237375c3230365c3237325c3231375c3333335c333634315c3031315c3231315c3031345c3336365c3232325c3234346c425c3334345c3235325c3232335c3033365c3332305c323737272b5c3230355c3330367b6c5c3033345c3231347c5c323336495c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3237315c3337304a7c5c323535565c3336325c3032345c3231315c303030645c3231355c3233302a725c323434495c3033305c3330325c3233372f5c3232355c3330377e3a5c3031365c3233305c3331325c3336365c333431265c333235545c3235375c3237375c3336355c3337355c313737575c3337335c3033365c3032335c3330354b5c3031375c3233325c3332335c3231327a4e5c3336315c313737755c3332375c3334325c3232375c3336345c3336355c3336345c3333305c3234305c3030302b5c3234355c323534717c5c3336315c3336305c323530465c3331375c3336355f2a5c3337365c3335375c3232355c3334335c3235376d5c3234335c3232355c3330375c3331315c3335313f5c3031365c3335355c3230344d6e3c5c3232345c3236375c333731615c3030315c3030325c333536565c3330335c3233365c3032305c3337317d5c3030365c3333375c333734705c323336315c3237323f3b5c3236345c323633595c3031365c3334316f5c3033345c3030305c3032353f2a605c3234365c303034476a5c333436315c3232355c333731715c3233365c323433685c333530465c3032375c3332355c3337365c3033375c3335314a5c3232315c3330345c3232365c3337364f5c3232355c3033325c3230315c3336325c3330345c3030325c32323459785c3333335c3232345c3331305c333530315c3233375c3335365c3334305c3033345c3231375c3333357b5c3333354f5c3335302d5c3236343d5c3335375c3334315c3334345c3030325c3032345c3236355f2a5c3033305c3031315c323136255c3336325c3332362c5c3235315c3330345c323534765c323433797d5c3236365c3334373e5c3231307a63315c333734695c333733765c3337305c3332357c415c3336315c3231322d5c3032325c3333305c323031635c3334315c333533485c3335355c3030305c323130642c5c3235375c323636475c333332365c3334335c303330315c3235315c3330374f2f5c3332345c3033355c323737715c3337302b4b5c323231215c32313062255c323031773e5c3337305c3234315c3033365b615c3330335c3030305c323737285c3031335c3332317d5c333036315c33313150225c3337345c3236335c3337305c3233355c3334325c3030355c333631775c3330345c3233375c3032346b5c323530585c3234355c3337365c3234373c5c3335325c333733725c3331325c3231345c3337375c303030225c3230335c3236375c3232355c3333325c303234675c3236363b635c3334355c3334305c3330365c3331325c3332345c3332347b5c3233375c323333715c333036255c3332325c3330315c3332335c3330335c3235375c3236372f5c3330323f5c3336305a39685c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3330335c3237375c3336355c3337355c3137375f5c3235375c3334325c3237375c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3331305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d33405c33373063613e5c3232336b713c525c33303771275c3232365c3331375c3334355c323636365c3030365c3336325c333736555c303336572b5c3231345c3334345c333733755c5c7c5c3233335c3332325c3234352a5c3333375c3031335c3337365c3237375c3235375c3335335c3237375c3236335c32323665385c3233345c333332725c3234375c3230365c3236355c3334325c3235365c3335365c3335355c3337355c3137375f3f335c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337325c3030335c3330315c3337375c3030305c3030317c3f5c3235325c3333355c3234325c3331345c323237295c32373244575c3032305c3331325c3030375c3232365c3031325c3334305c3230353e573c5c3234303c5c3336335c3230307a5c3030315c3232345c3336355c3235375c3031305c3337365c3330365c3233365c3031305c333235675c323131275c3033325c323234655c3233315c3032315c323134372a365c3030325c303136765c323337275c3233375c3237323d38535c3330305c3030305c323632747d4e5c3235375c3336355c3337355c3137375f5c3233375c3332305c3337375c3030305c3235315c3233315c3234375c3336377e5c3337375c3030305c3337305c3030375c3330345c3236315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237375c323433765c3337375c3030305c3236305c3032375c333033285c333433425c3137375c3236355c3234335c323237605c3031355c3334355c3333355c3234315c3030305c333431415c3330315c3336325c3330375c3336377d5c3030375e5c3230335c3031335c3236355c3332315c3337365c3330303f5c3031335c3334325c3330365c3330365c3332365c3032345c3230305c303036455c333134605c333634515c3337375c3030303c5c3337335c3335355c3337354f5c3234325c3334315c3337354a5c3235305c3137375c3235315c3237315c3234375c3336377e5c3337375c3030305c3337305c3030375c3334375c303234712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3332325c3031375c3333305f5c333031365c3337323f5c3330305c3233335d415c3234315c3231363b5c323135565c3337325b5c3236325c3331325c3230305c3232355c3031305c3331335c303330504a5c3336345c3337355c3330303f5c3331335c3030345c303134323f5c3333305c3030375c3334317c585c3333305c3333325c3330325c3232305c3030305c3331305c3237315c3231345c3033365c3231323f5c3334375c3233377d5c3237375c3235315c3336345c5c7b5c3331375c3230325c323734235c323437785c3030375c3330327a575c323037745c323234645c3332335c3236345c333333755c3236375c323034395c3030355c3231325c3235305c333532485c303030645c3336324e5c3030305c3033345c3336305c303035755c3334315c3236305c3332335c3234353e695c323337555c3330335c323334395c3231325c333133315c3231375c3032315c3231325c3236355c3237316c5c3235345c3335375c3235335c3337375c3030305c3230305e5c3033324d5c3236325c3334376c685c323337325c3236325c3335355c3231353e405c3237333e515c3330374f5c3232317d5c3337305c303330235c3030335c3032335c333033656f6e5c3330315c3234325c323032385c3231305c30333341445c3030335c3030335c303030635c333632555c3033375c3336305c3032315c33353153515e5c3233315c333732605c3333305c3334334863585c333433505c3231305c3234302a5c3235325c3231345c3030305c303037405c30303578775c3335355c3032355c33373345685c3137375c3030375c3236345c3237305c3335355c323536224b5c3337375c3030305c3032325c3331325c3230305c3330355c3234365c3330355c323733785c3030345c3230325c3033345c3331315c3236375c3334355c323137725c3337355c3334315c3336335c3032325c3233345c30303041685c3331375c3333325c3230375c3336365c3231355c3236365c333730235c3334315c3337305c3235352c5c3033322b5c3233375c3032345f5c3235366d6d5c3336335c3237305c3330325c3233335c3236315c3334373a5c3334305c3337345c3233315c30313439205c3232325c303136385c303134575c3336334f5e5c333237755c3031375c3032335c333533375a5c3236365c323533705c3336375a5c3230355c3331345c3233335c3334365c3233345c32353648635c3236375c3334355c5c205c303333385c3330375c3033305c3030305c3031345c3031345c3030315c3336325c3337315c3333305c323334525c3234375c33353643735c3336335c333736225c333432555c3232375f5c3031335c3230345c3332365c323537575c3332323f5c3336307c5c323732755c3335345c3336357c795c3336315c3030375c5c5c3337305c3232315c323536365c3235335c3235365c5c5c3337315c3236335c3030335c323635235c3230363d5c3236315b5c323032415c3333315c3032325c3230355c3330365c3330335c3333345c3336355c3334335c3235375c3033372f315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336315c3033345c3233345c3233355c3333335c3333375c3337325c3337365c3237375c3235335c33373627565c3235345c3335335c333136552a495c3237313d5c3333335c3333355c3337375c3030305f5c3332375c3233315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3331355c3337375c3030305c3235375c3335335c3337325c333735735c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331333e5c3233355c3234355c3331377d745c323230595a49355c3331335c3232305c3234322b584b5c323736705c3237372a5c3230305c323331655c3330305c3334345c3336365c3330376c7c5c3237365c3330375c3334305c3137375c3333305c3335375c333432575c32313423595c333233435c323137425c323636625c3032345c3331355c323531305c3231305c32343370365c3030345c3031305f5c3033345c30303049515c323134735c3231347c5c3236375c3033305c3331327a475f5c3335335c3337325c3337365c3236375c3335335c3330335c333431315c3033305c3236375c333133425c3233335c3232375c3234326f5c3337325c3337365c3237367e2b5c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336365c3137375c3230365c3137375c3334305c323334375c3030305c333037265c3236375c3334325c3335337b62465e2d325c3331377e5c3332335c3230355c303333555c3333336f5c303334775c5c5c3336303a715c3236375c3237365c3332323f5c3334305c3233365f5c3031365c3335345c3031323d5c3331365c3235315c3235365d5c3331323e5c3336305c3032325c3330315c30333464715c3330305c3030322d5c333030605c3030315c3336375c3237375c3232305c3330375c5c705c3232355c3234355c3332305c3337326a3c255c323333555770515c3336356b5c3336345c3237375c3336355c3337305c33373679475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c333735255c3337355c3230377c5c3032336f5c3234337c5c3030355c3332335c3335375c3233325c303130635c3237305c3332356f255c323734665c3231355c3032345c3232305c3032355c333236305c3237312b5c3332335c3336375c3030335c3336345c3330365c303136313c5c3033375c3236305c3232375c333032785c303130234d5c32373624715c3337375c3030305c3033375c323134385c3330305c3033305c3334305c303137415c3337327a5c3031347b5c3230375c3230357c315c3234375c3337302f5c3330337a6e5c3230355c3234345c3330302d5c3236345c3333353e5c3030345c3236365c3236375c323130735c3236355c30323460675c3332345c3337325c3233325c3335365c333033615c3234354a5c5c5c3332327d5c3031375c3236375c3334315c3331365c3033345c3330345c333435785c32353162312d3f765c3331325c3331355c3237365c3235335c3331305c3237305c323732755c3234326d5c3333336b5c3031325c3335355c333036315c3033305c3033305c3330365c3333347e5b5c3032335c3337365c3337315c3033365c3230325c3233375c3031355c3232355c3237355c3237335c3030365c3231325c3031305c333432206d5c3030355c3032305c3031345c3031345c3030315c3231375c333131545c3137375c333030475c3234354d457a475c3335315c303033635c323135215c323135635c32313542225c3230305c3235325c323532305c3030305c3033355c3030305c3032345c333532285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c303137205c3337355c3235353c4d5c3337375c3030305c3031305c3236375c3330305c3031375c3032364e5c3033305c3031316e5c3234304b5c3032345c5c5c3336325c333336735c3235346d5c3231365c30313745663f407a755c3033375c3232355c3236315c3330345c3236315c3233345c3231305c333034645c3032305c303131445c3337335c323737775c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337355c3334375c3337375c3030305c3030355c3032365c333631215c3236365c3336305c3231375c3230345c333634255c323237685c3237335c3237355c3232325c3336315c333235396c465c3234315c303237235c3030375c3230335c3334365c323637395c3033353d5c3236323e5c3031345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c33343063657a5c3332365c3335345c3237375c3235375c3331345c333734275c3231345c3236315c3033365c33323733745c3332335c333730225c3232375c3333375c3235375c3335325c323032385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3334305c3237375c3336355c3337355c3137375f5c3235375c3330325c3337375c3030305f5c3332375c3336355c3337375c3030305c3030355c3332365c3336365c3333315c32323156385c33303239605c323737225c3337355c333232765c3231355c3235335c3336325c3336325c3234375c303033275c3236363b635c3334355c3336375c3337353e5c3330356c5c3335345c3335355c3334335c3231365c3333315c303231625c3336325c3232335c3231305c333630505c3030315c3031305c3330305c3337355c333337235c3031335c3332375c3236365c3332315c3331325c3334335c3334345c3336316f5c3030365c3335315c3234325c3335375c3330345c3337326c4b5c3033325c3234305c3336335c3332305c3237365c3330355c3337335c3234306d25575c3031315c3331325c3232305c3237357d5c3237325c323134657d5c323732285c30303055745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313d5c3231345c3031325c3336375c5c5c3237335c3333335c3337325c3337365c3237375c3334315c3337375c303030605c3334304c3d5c323531575c3330345c3237365c323535475c333536575c3137375c3233325c3337365c3236353a5f5c3031365c333130615c3031325c303231525c3030365c32303572225c323136324a5c3032355c3231355c323136515c323636745f6c765c3335315c3231345c3235375c3235365c333730575e36332a5c3030305c3236314b5c3232305c3032315c3332315c303030395c333030455c303031425c3031345c3032305c3032355c3231364e5c3031305c333332485c3031335c3236355c3232363f5c3031325c3236345c3233335c3331335c3231313f755c3334355c3330345c3030325c3235365c333035465c3337355c33333121705c323532365c3031345c32353727275c3236363e5c323733765c3234305c333631235c3333335c33353665575c3231345c3231375c3232315c323134515c3030353b5c3331312559705c3233355c303031655c3335315c3332336f555c333332365c33373277675c3335325e475c3332345c3032315c3337305c3332336c536d5c3236374560563d5c3234375c3230335c3335325c3031325c3232305c3234305c3031346d5c32313725483c60635c3031315c3334355c3331305c333736355c3030335c3335355c303333215c3231305c3232342b5c3031305c3330302b5c3237305c303134615c3232375c303130315c333637235c3331315c3033334f5c323436305c3237365f5c3331355c3236335c3337305c3334335c3331345c3231365d5c3236365c3335375c3032335c3031355c3236305c323531455c333031535c3230305c3032355c3230365c3032335c303334623c5c3232315c3330305c3333327a6d5f2d6e3c6f5c33343647365c333333765c3230355c3230365c333330545c3330365c3237302a705c3030325c3236305c333032635c323134475c3232365c3033347c5c3234375c3234365c3332355c3336325c333035705c3332305c333732455c3337346a5c3030375c33333236435c30323128565c3032315c32303057705c3033305c3330332e5c303230635c333536475c323232365c3233374c617c5c3237335c3232367e312f7051625c3230302c475c3230325c3236315c303036255467705c3030315c303037415c3032345c3137375c3333355c3335375c333637465c3332335c3033375c333134575c303336375c333633235c3233336d5c323733425c3330336c2a635c5c5c303235385c3030315861315c333036235c3331335c3031363e535c3332336a5c3337317d5c3232375c3230345c3336355c33343177325c3032335c303334684a5c323035455c3032315c3335355c3331302c5c303230615c32303463276c595c3330305c3330305c3337314f615c3231305c3233375c3235305c3233315c3336345c3235365c3231375c32353028645c3230375c333133485c3334375c3333345c3235325c3236322a5c3030356c655c3032345c3234305c3030313d5c3032305c333437207d5c3330335c333637765c3236305c3231335c3235305c3231345c3237315c3231354c5c3231325c3032355c333630372a5c3233345c3230307b5c3334305c333430675c3336325c323537395c333630645c333736785c3230305c3032315c3033323b325c3237315f275c3030315c3236332e7e5f5c3232335c3030305c3337345c3230345c3336315c333230275e5c3030315c3231335c3332312d5c3332335c3331325c3236375c3231313c5c3236345c3231336a5c3230315c3334355c3330375c333637575c3231365c3230335c3230315c3330305c3337325c3031325c3234315c3033345c3330375c3330352f5c3231305c3032363f5c3031335c3337345c3030375c3235335c3337305c3232325c3337355c333234255c323334245c3330355c303333755c323332535c333034715c32313776625c3030375c323637245c3336305c3031315c3235375c3331305c3331375c3032316b5c3236375c3333362a5c3336315c3031365c3234335c3235366a5c3232325c3233335c3231354e5c3337365c3334315c3235362e6e5c3030325c3031345c3233315c3033305c323032425c3334315c3030305c3333327d5c3236305c3030305c3033305c3033305c3030335c3334355c3337325c3233375c3336365c3337315c3337305c323736755c3333375c3032325c333331785c3032374e5c3237305c3031355c3234375c333531456e6f5c333332315c3232325c3332374c305c3235315c3332305c3334342a315c3331315c3030375c3230325c3334373c5c3235375c3331335c3336322c712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3030375c303331575c3233367c5c3235315c3335305c3231375c3330325c3237305c323733345c3337325c333436335c3335325c3332345c3333375c3237314f4f59755c3337335c3236365c3337335c3337335c333532475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731675c3332335c3336345c3334375c3237345c3237345c3230365c3333365c333336205c3236334a5c3335335c3033305c3333305c323737755c3231365c3332305c3032345c3033355c3237345c3235375c303033275c3236363b635c3334355c3334305a5c3237332f5c3335335c3337325c3337365c3237345c3337365c30333231735c3232325c323134756f5c3337325c3337365c3237375c3235335c3337325c3033375c3330325c3231375c3031365c333731565c3336335c3335326d6c5c32353064645c323136365c3031303e505c303331325c3032335c3334345c3334354e5c3030305c3331375c3033305c3333335c333234635c3334355c333633715c3033325c3235335c3236335c3031305c333236335c3232315c3232335c3033327d5c3332335c3336325c3337345c3235335c3336325c3336325c323734727b635c3236363e5f5c3234315c3237342b5c3234325c3235355c3230355c323334565c3332365c3336365c3235325c3234325c303330715c3232305c323034325c33343234275c30333720247c5c3234345c3232335c333333685c3335315c3231342f5c3331375c3031335c3032325c3330365c3330345c323534623e40255c3032335c3335365c3337355c3333375c3232357e5e575c3231364f6c765c3330375c3331335c3333375c3231315c3230375c3236335c323034225c3333375c3137375c3332335c3337325c3337365c3236355c3337355c3030375c3231315c3336302b2d5c3330305c3334305c3236305c323533745c3234375c313737365c3337316f5c3337305c3337375c3030305c3232305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3233375c3137375c3335335c3337325c3337365c3237375f5c3331373f5c3235375c3335335c3337325c3337375c3030305c3230335c3333377c23515c3033355c3334365c3234305c3231335c3031325c30303244245c3335354f5c3237335c323037515c3230355c333731395c5c775c3334335c3234305c333434632b5c3335315c303231405c3030305c3031365c3232365c3236315c3330355c3336335c3330375c3330325c3234315c3033333f5c3332357c5c3235335c3337335c323736575c3231365c3237355c3236365c323136575c303337275c3232357c2a5c3031335c3031375c32313065555c32303541685c3232345c3033355c3235303e425c3033362e5c3032345c3335345c333435705c3237357d5c323037235c3033315f555c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313e5c3230335c3031305c333537455c3033375c3237375c3336307d4e7c5c3234365c3031335c3337315c5c5c3232375c3334335c3137375c3332345c3335365c3237365c303336275c3335375c3235355c3331325a275c3331325c3332317e5c33353146365c303134315c333032653d5c3237325c30333470335c3230315c323637727d5c3033335c3336305c3333375c3031352d5c3233375c3232356c5c32363129305c3235335c32343720285c3337315c3231305c3031323c5c3237345c3336315c3230355c3337314e3e5c3335316c5c3031355c3237335c3234335c3337315c3233375c3330312e5c3230355c3232305c3031305c3234315c323130465c3235325c333336595c3030355c3031346029395c3231345c323230385c3033315c3030335c333730715c3332375c3334355c3333335c3237313e5c3231365c333730795c3031365c3334355c3236355c3330355c3235305c323233615c3231335c3031305c3234336b5c3235375c3331325c333334275c33313030785c3335315c3336325c3334335c3232335c3230355c3333335c3237313b3c5c3331375c3236336b5c3237315c333535565c3335315c3334355b5c3330345c3233365a455c323635405c3336325c3334335c3337335c3235335c333037415c3330305c3334307d5c303035255c3331355c333034765c3232365c3336325c333137335c32353471445c3234355c3333355c3333305c333430285c303033245c3233324b225c3031355c3233345c303333635c3032305c3231372d715c3033325c3230325c303032715c3332305c3030325c3030315c3033305c3336375c3030335c3335302b5c3230355c3337305c3337375c3030305c323536375c3230373e5c3031325c3337305c3332325c333731375c3231315c3032374b5c3233362464245c303235695c3032345c3330365c323534305c303137425c3330305c3337365c3033355c3237325c333231275c3331325c3233335c33353473575c3235325c323530525c323335575c333636535c313737725c3237315c333731715c3336313f5c3330355c3336325c333734405c3337305c3231335c3334322f5c3032324d5c3233355c3337325c3230355c3335335c3331325c3033305c3030325c3330355c3032332a23404a5c30303254225c3235305c3331315c3337365c3335376c7c5c3237345c323534712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e55485c323236335c3232305c323032335c3232305c303131445c3337335c3234375c3334355c333731575c3334355c333435785c3334345c3336365c3330376c7c5c3235315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334352e5c3333365c3235355c3337375c3030305f5c3332375c3336355c3333375c333731665c32343549555c3233345c3235324d5c3333355c3237355f5c3331375c3337325c3337365c3237325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372a5c3237375c3336355c3337355c3137375f5c3235345c3137375f5c3332375c3336355c3337375c3030305c3030375c3332353e5c3033315c333730663b5c3031352d75236f5c3032315c3237305c323730745c3030305c3230345c333436255c3031345c3230336a5c3233355c323037205c3230315c3232327b6d5c303033235c3033372771605c3231335c303133795c3234325c333331215c3033372a5c3337345c3232315c3233345c32343656305c303235465c3330304a5c3336315c3331313d365c3231345c3334335c3033305c5c5c3235375c3031355c3330335c3033375c3336365c3032365c3233365c333630415c303130505c3232305c3230325c333231285c3337314e215c3331305c5c475c3331305c333731793d5c3236365c323136575c303337255c3337305c3234305c3030305c3030374b585c3334325c3337315c3334335c333431505c3231355c3233375c3335325c323736555c3337355c3333372b5c3330375e5c333333472b5c3231375c3232335c3335315c32353145465c303131235c33373273295c3330325c3332335c3330326069525c3234375c323632495c3333375c3237337a5c3236375c3336333d5c3031375c3330335e225c333733245c3335335c3237355c303033203b5c3334345c323135635e5c3230305c3236345c3231345c3331305c323431303e5c3335325c3031364f615c3331305c3030305c3032345c3336365c3337375c3030305c303132785c3332324b585c3032355c323433585c333434405c303030285c3332315c3336305c3231365c303130635c3230325c3331325c303131215c3230305c3030345c3336307e5c5c70546d5c333731665c33313276485c3332345c30333044505c3231355c3235325c3032315c3032355c3237364255305c323532365c3031375c3232375c3232335c3331376c735c323136425c3336357a4f5c3231325c3033325c333131595c323032215c3232315c3033307e5c3335355c3232342a6e5c3331317d5c3331325c3030325c3030315c3231345c3335345c3030375c3233365c3330335c3033302a5c323435366f5c3236315c33353325667d5c3231375c323430785c323632275c3236375c3032315c3232365f2d5c3030305c333333235c3235315c3231355c303032676e5c3032375c3031305c3030375c3030315c3033355c3237337d5c3333345c3337345c323433705c3231375c3234305c3236355c3332345c3230355c333234292a5c323536535c323035725c3234315c333131575c333430605c3030325c3234305c3232305c303131205c32333630415c3331305c303330385c3337314f405c3336315c3230325c3236355c323431475522315c32323423285c323336586d5c3234302f5c3331305c3234335c3234323b5c3033345c333430715c33373423704e5c333337485c3336315c333732446352515c3233355c33373030465c323035365c3331304e785c3330325c3235315c3334305c3231345c3033365c3030315c303336595c3337335c32343630515c33333531585c3337325c3031325c3237314b2f5c3230355c3337365c3033315c3332337c7b2f5c3231345c3235345c3336345c3235302d3c413d5c323433594f735c3031325c3230355c3336335c32343367565c3331335c3030315c3330316c5c3234305c3337315c3237325c3232315c3330315c3331365c303036315c3236346f5c3032355c3234335c333334285c3231355c3334315c3031355c303336725c323631225c323531315c3230325c3030375c303134515c3137375c323036355c3331375c3030305c3030315c333530395c3230375c3235375c3236345c3332375c3234335c3237315c323235236d5c3230315c3233335c3030335c3031315c3237355c3231306f5c3232375c3231345c3032345c3033355c3336375c3231367a6c6f465c303132345c3233365c333436535c3234355c3031325c323135395c3330353b3b5c323537275c3333355c3033325c323634514533405c3234325c323132285c3030305c3235375c3331365f5c3333335c3334375c3330345c3137375c3333335c3033375c303333615c3332335c333237705c323137485c3332335c3234315c3236376c655c3236305c3335365c33303652405c3333335c3330302a5c3335305c3031315c3337375c303030647e5c3033375c323433245c333430575c333434575c3330375c3033375c303231375c3231335c32373631785c333033586e7c5c3335354e54595c30323549215c3032345c32303440325c3237312a555c303237245c3336345c3330376c7c5c3237366e3a565c3230325c323137735c3336335c333136365c3330347b3c5c303034285c3234375c3235345c3334355c3337302f5c3337303638485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3330335c3237375c3336355c3337355c3137375f5c3235375c3334325f5c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c333732375c3330324d3424775c3332376b5c3030325c3030335c333436455c303236553e5c3334365c3033315c3031315c3031335c3336325c3033345c3235365c3030305c3334375c3231346d5c3033345c323134653c5c333436385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3236317c375c3332335c3237365c3331315c3334316b675c3032365c3236315c32343349365c3336362a5c323731232d5c3033305c3030315c313737775c3331325c333431473d5c3236365c323136463e4e5c3335345c3033325c3334365c3235337e5c3331335c3337325c3337365c3237375c3234375c3336365c3337345c303335435c333333665c3235325c3137375c3331315c3032365c3337375c3030304f5c3332345c3335353c3f665c3232335d31365c3235315c3032325c3231305c3333305c3233372d4a5c323634785c3231315c3031365c3332355c3337355c333330257e5e735c3337355c3332305c3031315c3033375c3330315c3336345c3030375c3230305c3336345c323330655c323235215c3032315c3330345c3236315c32323321325c3330345c3237335c3033315c3031365c33303524605c3234325c3231365c3031325c3233355c333331206530765c303136235c3336315c3333375c3030345c3335315c3236325c3236355c3331325c303330625c323135305c3335304c315c3234305c3331325c3236365c3330325c303030465c3333323a635c3332354f5c3033315c3331325c3230355c3333345c323337415c3337343f5c3332325c333435265c3032365c3230315c3032375c3235346c5c3331315c3334355c303035705c33333659555c30313242295c3334336f4f5c3232345c3336315c3233375c32323026535c3333364e5c3334375c3335376f5c3331305c3336365c3031375c3031365c3330375c3337335c3235355c333733216d5c3237314f355c303233615c5c2a5c3031355c3234306c5f5c3335365c3334305c3337335c323436303e5c3335326d554d2e5c3032345c3230365c3330325c3031355c3236315c323534655c323433425c3330302e5c3333345c3233355c32343072365c323537605c303037415c3332335c3234305c333531565c3335325c3231315c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c3031325c3337345c3332305c3337355c3237307c4f5c3337375c3030305c3031315c3032375c3330375c333335425c3333355f7c3a3d5c3236345c3032365c3031305c3335303241204a5c3331323e5e5c3233335c323434205c3233345c3336315c3236375c3235375c3033372f5c3335316b5c323630452c4e5c3030305c303331245c3332375c3334335c3237375c3330345c3235375c3032315c3235375c3231347e225c3337305c3233335f525c333035755c3031354a6b5c3230357d5c3234345c3236325c3235333e55465725765c3230355c3033313d315c3333335c3033372f5c3233315c3231365c32323250515c3335375c3337357e5c3234375c3334365c3337346f5c3231315c333636783a78755c3237345c3334355c3137375c3232325c3337375c3030305c3230325c3332315c333134475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323736255c3337375c3030305c3235375c3335335c3337325c3337355c3137375c3032375c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3332365c3237365c3032375c3335315c323337655c3336305c3333305c3233345b465c323535355c3331303b5c32323572545c3030365c323131705c3237375c3237335c3334357e535c3331375c333733235c3232315c3231375c3232335c3331315c3234335c3231316339585c33303467205c3032325c3231315c3336374f5c333132365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d5c333437415c3332325c3237375c3236325c3336345c3231332b716b5c3033346f5c3032305c3230355f627d5c3332365c3330345b5c3230325c3337365c3335375c3232315c323230795c3335355c323634725c3237305c3337313d2c5c3032325c3237345c3333345c3237345c3237375c3235375c3335335c3337325c3137375c32343370465c3033375c333332635c323532577b423f5c3231335c3137375c3334345c3233375c3336355c3237375b5c3334305c3333335c3031305c3333365c3335344c5c3230323b695c3032346760405c323436315c3334355c3230315c3336325c3032325c32343321765c323537275c303034635c3235325c323035253e5c3231335c3336305c3031355c3234375c323236515c3232305c3234326c5c333331235c32353346236044585c3030354e5c3330355c3335315c3230315c3233375c323732475c3235325c3030345c33313278775c3230315c3235345c303330496e5c323535645c32343177475c323635635c333433685c3330335c3031375c3333355c3236365c33333750405c333434635c3030345c3336315c3236377a7b5c3233375c3230336e5c3334335c3236375c3231362d5c3332315c3235325c3231305c323231725c3230365c3032365c3031365c323333632d5c323731305c3235335c333230715c3337343d5c3137375c3230345c3235365c3334345c3336365c3235355c3332345c3337355c3236305c3336365c33313528476b645c3234342b5c3235313e58655c3032305c3335355c3330315c3333305c323132305c3030322e474e715c333037235c323030303f335c3137376c3f5c3030375c333331784b5c3334335c3330365c3236365c333332755c323734765c3332367a5c3231325c3330377c5c323736425c3231365c3033355c32303059305c3030325c3336305c3031345c3232315c3237367938235c3235305c3330365c3032375c3335365c333335475c3330355c3332315c333037675c3236325c3333345c3330365c333534465c33323052205c3231345c3234305c3030305c303033295c3333303a5c3033305c3332335c3332335c3231345c3032315c323032405c3231335c3334303f5c3333325c3232375c33303550785c3236335c3334325c3337355c3336345c3236365c3337305c3336325c333534615c3231325c3330377a7c5c3330354a5c3334305c3232345c3033372e305c3031312a5c3333305c3334305c303235206d5c3030335c3031335c3334375c3334335c3235355c3335345c3332375c3235315c3337315c3335375c303333465c3033375c3333315c333231725c3337305c3237315c3232355c3237365c333437735c333130235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3031365c3337375c3030305c3332375c3336355c3337357e5c3237375c3230375c3337375c3030305f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3333337c265c323634235b5c3237315c32323521505c30323624565c3333325c323337745c323331225c3334317e4e465c3032375c3235375c323637515c3231345c3235375c3032335c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3332355c3337365c303133686c5c3236365c3236375c3236375c323131685c3237315c3232305c3335345c3333345c3235315c3331325c32303450484f5c32323465715c3332345c3336365c3333303d3e5e5c33313422725c3235325c3233327b5c3137375f5c3332375c3336355c3137375c3235335c3334317a2e5c3236366d465c333337665c3335355c3337345c3232375c3337315c3333335c3337325c3333375c3332325c3336345c3031355c30323229655c3331375c3232375c303234525c303230465c3330345c3030305c3030345c3337355c333337456d5c3233305c3333323c5c3236355c3331316c745c3033345c323030325c3237365c3336375c3334302f5c303136465c3331325c3331305c3332315c3330355c3031325c323531662c5c3235335c3334355c3237305c3031345c3231325c3330375c3030305c3234325c3230325c3030315c30303376485c3033372f5c33363028223e275c3330305c3233365c303131685c3334345c3230355c3330345c3031335c3236365c3333305c3334345c3030345c3231345c303230365c3032365c3337335c3234305c323530235c3031335c3332373f775c3033375c3333365c3033375c3237325c3337325c3030335c3330325c3033365c3032355c3032365c3031376c5c333736425c3334325c303237505c32373362255c3030365c3332375c3333335c3336325c3337345c323331525c3030335c3031345c3230335c3332335c3033355c323130262f5c3234305c3332345c3337365c3230375c3332305c3231335c3334325c3033365c3235367e5c3033365c333734215c3336315e5c3235375c30323431472d5c3235355c3230345c3335375c3032345c3230315c3033315c30333164744d5c3234305c3030315c3033303f785c3231345c3233365c3030302a3e5c3335305c3334313f275c32323225462c235c3032315c3233345c3230304a275c3333353f2f5c3331325c3237372f2b5c333037275c3236363b635c3334355c3337355c3033325c3337355c3237335c323734495c3337355c3230315c333630265c30313529405c3230324d565c3337325c3333365c3333315c3234315c32303065555c303233325c3232303e5f5c3237325c303332345c3033355c3030375c3030373c625c32373739235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337305c3237305c3335315e5c3234325c3231375c3232315c3337305c3231375c303333623d5c3234363a5c3032345c3032365c3332315c3231375c3334325c3333375c33373158235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f365c3337375c3030305c3332375c3336355c3337357e5c3237375c3233355c3337375c3030305f5c3332375c3336355c3337375c3030305c3030366d3e5c3330375c3335355c3032375c3232305c3330335c3032347b5c303336495c3032363f5c3333355c3234364a5c3232335c3236345c3030355f5c3232375c323235385c3033313e5c3333355c3236315c3336325c3337335c3336355c3234355c3234325c3330315c303034423b545c3231342b445c323734265c3031325c3031375c3333357c5c3235335c3337335c323536465c3032375c3235376d5c3234335c3232355c3330375c3331315c3334335c3137375c3031375c3336345c333431715c3334325c3235335c3032325c3236305c3235305c303231485c3236323e5c3330355c3337335c3237305c3333335c3230305c3237304e575c3230315c3331375c323637515c3231345c3235375c323633455c3030305c3030303a5a5c3330375c3032375c3331375c3033375c3031325c3230346c5c3337375c303030555c3336325c3235375c3335365c3337315e3a5c3336365c333332395c5c7c5c3233365c3331365c3031323e5c3334335c323237735c3336365e5c3030355c3330335c3336325c3334315c333533625f5c333332697d5c3331325c3337375c3030305c3235375c3336355c3237315c3332375c3337305a685c3235345c3232355c303033415c3033346e5c3231325c30333024605c3236375c3232365c3032355c3033305c3232325c3233305070305c303037555c3336355c333731485c3031345c3233365c3330355c3334315c3331375c3032312d5c323033455c3031325c3236325c3336305c323430275c3232365c3237373c6e5c3032302a5c3334335c333637436e5c3033305c323736715c3231345c3032343d5c3031325c3233372f5c3330306d6e5a5c3031305c303232255c323032385c323433505c3235325c3331325c3231304e5c3330365c3330305c303030275c333132325c323730635c3331305c3330305c3033305c303334715c33303743635c3334326f5c323633445c3337305c3231346e565c3030335c3331335c3030335c3331335c3033335c3231312c59765c3235305c3334333b335c3331375c3336305c323134605c3235325c3233305c3337353b5c333333535c3336345c3333365c3230375c3332335c3330375c3330365c3230345c3031315c303231635c3236365c3031335c3033375c3331325c3230376e375c30303038205c3231305c3330315c3033375c3335325c3334335c3033375c3330327d315c3336325c333731615c3336315c3234315c3330345c3235305c3236315c3333335c303035435c3236355c3031365c3333346e5c30303070415c3032315c3230323f5c3332355c3330363f5c3230345c333732635c3334355c3336325c333736725c3232335c3330365c32303556605c3232305c333032765c333432355c3333335c3336325c3335365c3030335c3234332e5c303230635c333536475c3331305c3333327d315c3230355c3336325c3331313c6855665c3031315c303134276e235d5c3237372e5c3334303a325c3334315c3030363e5c3334347c5c3231355c3234375c3332335c3033305f2c5c3237355c3330347d5c3033327c68712a2c765c333031505c333535435c3236375c3033335c3230305c3033345c30323044605c3231375c333635715c3231375c3334313e5c3233305c3337317c5c3237315c3335347c6b205c323731655c32313121415c30333640785c3334325c333133322a5c333632405c303130385c333034495c323230765c3336375c3337335c3234335c3030363f5c3233325c3334345c3336315c323431555c32333024305c3233355c3237305c323135765c3337345c3237335c3230305c3335305c3331335c3230345c3033305c3337335c3232315c333632365c3233374c617c5c3237355c3331375c303137785c3234316e5c323537515c3032315c3234325c323037636d2523515c3233305c333736515c323230765c3031375c3334315c323135735c3330305c3330305c3030375c323030395c3231305c3332315c3230355c3233335c3332315c30333751693a5c3235316f2a5c30303655595c3232305c323534715c323730505c3234342e5c3334355c3030355c3032345c3030345c3334335c32303462725c3030375c3333353f776b5c3031305c3236307e355c3337345c5c5c3332335c3337365c3031305c333734395c3237305c3332365c3235365c3232325c3032337a5c30323041635c3234375c3234335c3033344d395c33343154605c3030335c3236317a5c3232335c3230315c3230355c3030375c32343562783f5c5c735c3032347753465c3232315c3330355c3033365c3333315c323437565c3333335c3033325c3234372d235c3032355c3030355c3030305c303337757e5c333636305c3032372768505c3332315c3337345c3032315c333733487c635c3233335c3334335c3032375c333034295c3235365c3334305c3232315c3230365c3230315c323437665c3332334c5c3230355c3032305c323532475c303336572c5c32313254705c3334345c303032495c3030305c33343028385c3333335c3230355c3334365c3330345754635c3334365c3336363e535c3231305c3236335c3230355c3232345c3334316f5c3031375c3334324b485c3235375c3331355c3337345c3237373b5c3033365c3137375c3334325c3237375c3032356a5c333336385c3336315c3033355c3336365c3237355c3235365d5c3331317d5c3235325c333336495c3237367b5c3232375c303331205c3233355c323430225c3337345c323737735c3030305c303136305c3030305c3030305c3031345c3030315c3336325c333433475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e765c333637776f5c3337325c3337365c3237375c3235365c3337375c3030305c333137735c3233345c32343727293b5c3236375c3237375c3233375c3336355c333735795c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5b5a4e5c323231365c3234377b5c3033355c3236355c3233355c32373667765c3031335c3231305c3332335c3335367d5c3333365c3030315c3333335c33363770393d5c3236315c3333335c3033372b495c3331315c3333316b5c3137375c3335335c3337325c3337365c3235365c3334315c303131545c3232325c3230345c3032336d5c3335305c3232375c3137372f5c3335335c3337365c3033365c3033335b365c323236655c3231365c3031305c3031315c3232355c3233302858635c3333345c3330305c3233355c3234336a5c3230305c3233345c3230335c3231365c3237365c3333355c3236315c3336325c3337335c3237375c3330325c3333375c3333315a5c3336335f5c3333317b5c3235375c333130745c3335305c303030245c333331592a5c3233315c3330365c333230325c3234355c32313261545c3030355c3334375c3235315c303330205c333535235c3334355c3335323e5c3031347c325c3332335c323734385c3336304c5c3336365c323631365c323431275c3232375c3237325c3334345c3230325c3031305c3331312a565c3032325c3032335c323030365c3336355c3331303842785c3333325c3031345c313737555c3337343a5c333230615c3231316d5c333236485c33343347655c3230355c3236325c323130412c5c303131435c3236355c323236315c333130553c5c3231345c3031342f4057747e5c3330355c3031345c3033325a5c3332345c3333375c3337325c3337365c3237375c3234367e5c3330315c32323370752a51555c3236335c3033377a5f5c3331337d5c3032375c3235355c3236377e5b7a5c3231365c333730495c33363057415c3336305c3032355c3233345c3033375c3333305c3237325c3033355c3230355c32313343265c3033365c333430445c3031345c323632615c3230375c3033335c33333177705c3030305c3334305c3336345c3330365c3031365c3031305c303336575c3235345c3333325c3333315c3330355c3030325c3234332d5c323634304a5c3032345c303032225c3030335c3031335c3330305c3030345c3030335c3230315c3330375c3331325c3234335c3234305c333431475c323435455c323437695c333131655c3032325c3032325c323130265c3333325c3030312a5c3235335c3336325c3337345c3235325c3234345c3030325c303235785c3337315c3030376e5c3330335c3234305c3030305c3031335c3236355c3335315c3234345c3232365c3231305c3337352a5c3032345c3334314a2a5c3032345c333232496c5c3232365c333031455c303234532c285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3232305c3233345c3031325c3030305c3337345c3335305c3337355c3237365c3337344b5c3337355c3236315c3336315c3235325c3333374e4c5c3231305c3336345c3231353a285c3033305c3231345c323232245c3232315c3231345c3230375c3030336f425c3235345c3230305c3232315c3337355c3332315c3331375c3336377e665c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3333367c735c3336315c303133785c3236335c3334335c3033375c32313435765c3330315c333633753963595c303231495c3337315c3032315c323034685c3030312b5c3232325c32343551724f4c765c3330375c3331335c3330315c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337317a5c3236325c3334375c323531265c3233375c3336355c3337355c3137375d5c3337375c3030305c323331336c4f5c3332365c3336315c3336355c3235335f793b7a6c5c3237375c3031375c3335335c3237315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3334335c3137375c3335335c3337325c3337365c3237375f2b5c3337325c3337365c3237375c3235375c3337303d3f5c3330335c3331335c3233335c30313523585c3232325c3335325c3336305c3330356e5c3235305c3231325c3235324a5c3032335c3236355c3231335c3330375c3330325c333432335c3232315c3236354f275c3033305c333037515c3231345c3235375c323431475c3334333d5c30303540645c3237305c3236365c3231375c3031375c3033303b236f5c3232335c333735575c3331325c3237375c3237325c3334357e5e5c3237355c3236365c323136575c303337275c323133475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3336365c3332325c3330354a5c32333454525c3337365c3237375c3235375c3335335c3237375c3332375c3334355c3233344f5c3231325c3331325c3236305c3335335c303135465c3032316a5c3335355c3333355c3333365c3336377e5c3231345c3336365c3233305c333734675c3234305c3235305c3031345c3232375c3032365c3332315c3334315c3334335c303037646d5c3336325c3137375c3235325c333731575c3336375c5c5c3235375c3331335c3332375c3236365c3332315c3331325c3334335c333434235c3336315c3233365c3230325c323430325c5c5b475c3230375c3231345c3033355c3232315c3236375c3331315c3337365c3235335c3334355f5c333335725c3237372f5e5c333333472b5c3231375c3232335c3330355c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731755c3337325c3336345c3337332f5c3335335c3337325c3337365c3237325c3337325c3333375c3335335c3331363f5c3337367d5c3330335c3335365c3232375c3337375c303030255c3337357d5c3330375c3236345c3330375c3334333d5c30303540645c3237305c3236365c3231375c3031375c3033303b236f5c3232335c333735575c3331325c3237375c3237325c3334357e5e5c3237355c3236365c323136575c303337245c3337326f5c323131745c323135465c333532382c5c3333365c3333345c3331365c3335365c32303152385c3331302b5c3230315c3032312a5c3237315c3231335c3232355c3330325c3233367b6d5c3033345c3231347c5c3233365c3033375c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3235375c3337305b5c3234325c3033335c3337375c3030305c3032325c3235345c3236315c3330315c3033375c3337322a5c3231315b5c3334355c3330305f5c323732305c323437665c3031305c3330305c3331375c3337345c3030375c323134632b5c3234352c645c3335324d465c3331335f5c3335335c3337325c3337365c3235375c333531655c3237345d5c323330635c3236315c3232345c3236305c3333365c333136365c323233495c3333313b5c3333335c3235335e5c333637635c333236215c323031705c3033316d52215c3237363e5c3032323e535c333735575c3331325c3234335c3331335c3334357e5e4f6d5c3234335c3232315c3231375c3232335c3332357c5c3030335c3234375c323534505c3333335c323634285c3231325c323431514a2c235c303333445c3333346d3b323e5c3234375c323134275c3030375c3231345c3330355c3334365c333732765c3233345c3335313e525c333236243b495c333034205c3032325c32303022645c303134205c333731705c323037245c333636515c3333335c3230355c3336365c3237375c303033695c3232335c323036775c333733325c3235365c3332355c3232305c30333725705c3234345c3334372c425c3335355c303034705c3237316e5c3233305c3330365c3031375c3333355c3031335c3033375c3235335c3237333f5b7b5c3033365c3332315c3334303d35205c3230365c3033375c3236335c32353446355c3031305c323037645c3033345c303234595c3237305c3333335c33363264723a5c3233365c3331335c3332375c3231345c3330355c3235335c333631775c3334325c3032355c3233375c3330323f5c3230365c3333325c3237375c32313065585c3230375c3333305c3234305c3333316b6c7859663f2c715c3230303b645c3231345c3334335c3234305c3030345c3336345c3032357b5c3330315c3332365c3033364c6d385c323035215c3337315c323435425c3032305c3336315c3336375c3232375c3030375c3033335c3030365c3031315c3330315c333136315c32303230405c3333325c3032363f5c3230375c3237376e5c3337375c3030305c3231345c3030335c3330355c323736365c3236375c333630765c3233352a5c3237365c3233335c3234305c3237366e5c3234355c3231335c3334365c333337765c333030657e5c3335315c3334315c3032345c323235383c5c3032325c3330305c3336323e5c5c6b5c3332345c333636545c3333345c3232365c3334375c333136675c3333315c3232325c3331325c333630335c3235345c323736275c3234347d5f5c3337316e7c5c3330355c3235325c333532573a5c3333365c3235377b5c3235325f3f5c3233317d77334d71325c3234305c3030345c3331305c3330345c3032325c3030365c3032305c3031355c3234375c3237315c3033305c3330363b635c3334355c3234375c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337315c3237335c3333375c3235375c3336355c3337355c3137375d5c3337375c3030305c3233345b726d5c3236375c3337355c3137375f5c33323772385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f6d5c3336305c3237335c3330335c323737695c3332345c3333335130205c3231365c3332355c333231465c3032335c3234335c3232325c3230335c3031335c333632725c3030325c3231365c3234375c3234375c303335315c3232355c3334325c3234335c3230356339585c33303467205c3032335c3033327d5c3332335c3336325c3231355c3235335c3336325c3336325c323734727b635c3236363e5f7a5c3336305c3032375c3230365c3231365c3231315c323435436c5c3236365c3235302655324a5130555c32313221603e415c3232355c303031704e5c3137375c3230307a617b705c3232305c3334375c323337376f5c3335335c3337325c3337365c3235375c3336365c333334235c3232375c3337357730555c3234345c3237355c3333327a5c3337345c3337365c3331375c3334335c3235375c3331335c3335375c3335367c3b5c3234354b255c3233314f5c323633475c3032325c3033305c3330365c3032315c303233207c5c3231365c3234335c33313325795c3030305c323032315c3330374c5c3336315c3236345c3236327c5c3233305c3236312c6c4a5c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3335365c3237375c3031345c3337307669745c3331335c333537325c3032355c3331305c3231324d5c333232435c3033305c3033315c3333325c3333335c3337305c303333415c3033305c3031335c333137425c3237305c333036725c323430455c3336305c3234325c3330345c3236315c3236312a5c3230323c5c3032305c303131445c3337335c323737775c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3335375c3231367a5c3330355c303337415c3330375c3231365c3335375c3031345c3237375c3330355c3337375c3030305c3236365c3337375c3030305f5c3332355c3230345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317c5c3235335c3337375c3030305f5c3332375c3336355c3337325c333736515c3337355c3137375f5c3332375c3337345c3033365c3233335c3334315c3237325c3031307c556a5c30323225525c333037695c3333325c323737775c3335365c3233345c3031375c3232335c3232355c3330325c3336355c3335355c3230315c3332335c3033315f605c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313c535c3330305c3335325c323630785c3235374c615c3031325c3031375c3333375c3235325c323334275c3031324e5c3332315c3230355c333731395c3033345c3031367b6072315c3232355c3336365c3237305c3234305c3030305c3030374b585c3334325c3337315c3334335c333431505c3231355c3233375c3335325c323736555c3337355c3333372b5c3330375e5c333333472b5c3231375c3232335c3333345c3330314a5c3336345c323736675c3335365c3033345c3032313e6c5c323732715c333535375c333731445c3335315c3237345c3033325c3330335c3335355c3032315c3030305c3032325c3032305c3231345c3234375c3331315c3336325c3331305c3333315c3231305c3231315c3337315c3033305c3235325c333431575c3332372b5c333136395d5c3237314f5c3234327c5c3030313c725c3330375c3032305c3231375c333131225c30323550432946425c32353272505c3335355f5c3237335c3332305c3334336e395c3337335c3230355c303133275c3331355c3333365c303136755c3236375c3237322c22585c3032305c30323129485c333432394d5c3236305c3231375c3237335c333632295c3330305c3330375c3235305c3335303e655c3333335c3336327d5c3031355c3336305c3336305c323530645c3333325c3336317120242c5b482b5c303236325c3031365c3330355c3330365c333334605c3336325c323730235c3235326d5c3337355c3333375c3234305c3237335c3033375c323431347b5c3336365c3233345c323733345c333733555c3333335c3236375c303231285c3333335c323134635c3230315c333036305c3237305c3337345c3230375c333230745c323537245c3337355c3236305c3031345c3231335c333733395c3337305c3330335c333133525c3335355c3334355c3333335c3230325c3030325c3334375c3231375c3236345c3330355c3232335c3332305c3336345c303331395c3335355c3335355c3332365c32373557455c3232315c3033365c333032305c3231365820545c3333325368425c3032345c3030325c3234335c3334355e5c323037395c3334335c3230335c3232315c3230315c3231345c303136275c3336365c3231305c3336305c3334335c3337305c3235375c3334305c3231375c3231345c3236345c3335305c333433334a5c3333327c5c3232335c3330375c3033305c3030305c323236785c3337375c303030785c3234305c3031345c303336725c3230335c303334755c33353047515c323335645c33333529255c3237355c3233315c3334355c333436705c3232355c5c5c3031357843775c303131255c333637335c3336324e385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c323235525c3032355c3231345c3334344623205c3230304a275c3333353f285c3333325c3237372f2b5c333037275c3236363b635c333435485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237372f5c3137375c3335335c3337325c3337365c3237375f5c3334365c3033375c3335335c3337325c3337365c3237375c3334305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3137375c3335335c3337325c3337365c323737535c3337325c3337365c3237375c3235375c3337303d575c3230335c323734645c3337365c3033345c3336325c3335355c3234365c323637592c5c3237345c33323527625c3031355c3332305c3334345c323436427c5c323337325c3337345c3234335c3332335c323437515c3231375c3232375c3332345c3336345c3331335c3331334d4a5c3030355c3237305c3236325b775c3231377c605c323330575c3337355f5c3337325c3235375c3232345c3031372f385c3337317a5c3233365c323333472b5c3231375c3232335c3330305c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c333135633c5c3233326c5c3330326b626d5c323434525c323737344b5c3336374f5c3331335c3230355c3033372f2b5c3336325c3231367b60745c3330375c3331335c333337475c3032372a69465a5c3234335c3335365c3236326e2b5c333034655c323631542b2e7a6b6e5c3335335c3332315c3336365c3336325c313737795c3336345c303034505c3030305c3030335c3234355c323534717c5c3336315c3336305c323530465c3331375c3336355f2a5c3337365c3335375c3232355c3334335c3235376d5c3234335c3232355c3330375c3331305c3335305c3032305c3330355c323131225c323637485c3031365c3334345c303037625c303230505c3032315c3032302a5c3237375c3237335c3331315c5c5c3031345c3032335c333333685c333435715c333632796e5c3232335c333631325c3335325c333134225c3333355c3333305c333031705c3235325c3335305c3033324850235c3234305c303035325c3032375c3334345c3330335c303134285c3334375c3030335c3335365c3336355c3033305c3331325c3336365c3233323f5c3231335c3236347d515c3230325c333030605c3236365c3232343c635c333133755c333332575c3233305c3230365c3332345c3337355c3333365c3033307c5c3237357a5c3231355c3234335c3232355c3330375c3331315c333532535c333034535c3235315c3336305c3236335c3336355c5c5c3031375c3032305c3334355c3237315c3230355c3232353a5c3232365c32323769685c3337375c3030305c3331315c323737465c3331365c3234325c3331365c3334355c3334335c3231302f5c323232235c3230346d505c3231305c3235355c3337335c3237375c3232355c303030555c3033335c3030375c3331335c3331315c3334375c323636395c3330372177745c3337375c3030305c3032335d475c3033332b285c3231345c333535215c323236255c3031305c303232435c3336336e435c323634645c30303247385c3337365c3032315c3332305c3235325c3335355c3334355c3234325c3230345c3030355c3031365c3232365c3236315c3330355c3336335c3330375c3330325c3234315c3033333f5c3332357c5c3235335c3337335c323736575c3231365c3237355c3236365c323136575c303337215c3032345c3030305c3030305c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c333632745c303337485c3331375a5c3332333c695c30333432265c3332365f5c3232305c3233355c3331316f5c3031305c3331315c323135405c333530765c3031375c3334315c323135735c3330305c3033345c3336365c3030375c3336375e5c3236335c3334315c3231375c3032375c3231315c3333335c3336375c3231375c3033325c3234305c3033335c323434485c3332305c3235375c3232365c3333345c3236315c3333325c3030325c32353127705c3333335c3333335c3232355c30303328505c3032345c333731565c33323679225c323135405c32303424605c3234325c3230345c3030315c3230305c3231345c3032305c3230336a5c3231355c3230335c3334355c3334345c3336335c3333335c3033345c3334335c3233355c3237355c3237375c3230353c4e5c3332365c3332325c323033225c3030315c3236345c3335365c323236245c323134765c3331345c323134635c3030323c5c3137375c3031325c3031345c3336315c333230745c333030315c3232375c3236365c3233335c3230355c3237335c323337625c333730775a5c3231326f215c303337635c3337345c323733215c3232355c3032347d5c3332335c3236345c303035505c323532385c333731493d3e5c333531385c30333359635c3335315c3235335c3330333c5c3033355c3334323f3a5c3333307c5c3330336a7251515c323736425c3032345c3237335c3232315c3336325c3230325c3330345c3032305c3234305c323232575c303333403b4a5c3030365c3231375c33333034395c3233364b65555c3333325c3332305c3234305c3031305c3031374d5c3234342a5c3031355c3234306c5e5c3337335c3236335c333530463039555c3236325c3031353a285c3234325c323030395c3237375c3231315e235c3337375c3030305c323034435c3334315c3336375c323131355c3237355c3331345c323535615c3234375c333137705c323035464e5c33343542575c3033375c3231362b5c3336315c3332336e64695c3031325c333535725c333337332a5c3334345c323032765c3336303e5e545c3334335c3232335c3335355c3333335c3033372f5c3335315c3137375c3335355c3331315c333432665c3336305c3337375c3030305c3330303b5c33373374255b565c3237345c3236375c3236315c3333345c303234315c303033715c3232345c3337366222335c3230335c3230307b755c3033375c3233315c3332315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317c4c745c32353751475c3331305c3337345b5c3231362b5c3336335c333433295c3332315f66375c3337315c3236375c3337375c3030305c3030315c303034712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3334365f5c3337325c3337365c3237375c3235375c3332375c3336335c3231375c3335335c3337325c3337365c3237375c3334305c323534305c3030305c333433645b5c3033305c3232305c3237375c3237334c5c3232307e515c3236357e5e545c333430645c333733765c3330375c3331335c3335375c323732565c3233345c3236365c3033327d5c323534496d5c30333279425c30323425635c3330315e215c3331305c3033375c3237325c3033315c3033372f275c3033346d5c3033345c3235363e4f5c3033305c3336307e5c3233342e5c3237344d5c3234365c3330365c3232305c3230315c3337335c3336342e5c30323063685c303333495521395c5c2f5f6e5c3234335c3033372f5c3237315a5c333333235c3032305c3330325c333335205c3033335c3232335c333536475c333132715c3032365c303235415c323134657e515c3232335c3332346d5c303335315c3336327a5c333730255c3335365c3331327e5c3233375c3332375c3336355c3337375c3030305c3031375c3337325c3337375c3030305c303032615c3235354e5c323736275c323733515f2d5f5c3334365c3237375c3235354e5c3337335c3334315c3337365c3233345c3234365b755c3232365c333235615c3030305c3330355c32363028385c3033345c3236303e595c3333315c3333335c3030375c3232315c3337355c33323270315c3237323f5c3234337e5c3033365c3335315c3332315c3231312d595c3335355c3332325c3030364f295c323231365c3232365c5c5c323036615c3231305c3331375c3232375c3332305c3030305c3137375c3335375c323032785c3330365c3335305c333734335c3330307a7a5c3330356f5c3030325b5c3234343e5c5c7b412b5c3031375c3030355c3030345c3234335c3033337e4e3a70485c3337365c303334675c3231375c3333357d275c3334305c303335395c3032365c3030345c3230375c33363766344d5c3335325c3332305c323430295c32303120235c3033315e335c3236345c3031365c3330375c3334355c333036495c5c455c3335325c3234335c333635375c3236315c3333345c3333335c3234375c3232356f5c30323279695c3032365c3332355c3030335c3331335c3231375c3335365c3235375c3033355c3030375c3030335c3230315c3336345c3032352536385c3332325c3033305c333236385c33323422285c3031325c3235325c3234335c3030305c3030315c3332305c3030314e5c32353224285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c303030285c3234325c3231325c3030305c3334315c333736375c3337305c3234315c3337345c3033315c3336305c3231375c3330355c3237325c3330344f5c3334355c3331376f5c3234374a21715c3233375c323236565d5c323130785c3334375c333537305c3337375c3030305c3032315c3332365c323737215c3332322542584623395c3030305c3232344f5c3237327e5f5c3232357e5e575c3231364f6c765c3330375c3331335c333732355c3337337d5c3337305c3233305c3335305c3337375c3030305c303035605c333233235c3232355c3232315c3336356d4a5c3033305d5c303235492d5c30333266435c3335355c3231355c3331335c3033375f5e5c3333305c3331305c3337345c3334345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c333431635c3234357a5c3231315f5c3234315c3337305c3232375c303333623d5c3234363e5c303234535c333730635c3337305c3236375c333736565c3337365c323637235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f3a5c3337375c3030305c3332375c3336355c3337357e5c3237375c3233365c3137375f5c3332375c3336355c3337375c3030305c303037475c3330335a6a5c3333365c3335335c3236365c3032365c333432305c323032495c3332315f6267685c3331325c333435475c3331335c3331325c333430727b635c3236363e5f765c3230365c3030355c303031596d5c323232215c3237323f5c3237315c303337295c3337365c3235335c3334355c5c5c3330375c3331325c3337345c3237345c3233365c33333347235c303337275c3232315c333734325c3332325c3332365c3334335c3330345c3236315c33313420415c3336366024384e5c3032345c3334355c3032375c3031335c33363272315c3331367b6d5c333532315c3232355c3336365c3033335c3033305c303235495c3232375c3331315c3231365c333331545c3030324a5c3235365c3333355c3233372c5c313737285c3331325c3031345c3235365c3032375c3030345c3336365c3333325c3030375c3033305c3330325c33373378385c3333325c3232335c323237735c3336365c3333365c3030375c3330335c323532785c3033325c3232355c3333365c3336325c3232375c3334305c3232375c3337315c323636755c3337365c303330685c323535604f5c333634645c3231305c3330325c3231325c3333305e765c3030355c303136495c3231345c3030355c3030375c3231365c303036323a5c3032335c3336325c333430347d5c3236355c3237365c3236375c3336365c3032325c3235355c323637615c32303466425c3232312a5c3232364c285c3333323e415c3230335c3231305c3231367a7d5c3332335c3232305c3233303e4f5c3230336a5c3137375c303235345f5c3031365c3231315c3235355c323430537c5c3336315c3233372c5c3234355c32373463683b485c303330625c3234375c3334355c3033335c3237315c333037715c3333305c3231345c3235375c323337785c3231375c3334325c3237365c3237315c3334325c303034785c3232355c3234335c3332335c3235355c3233315c323736655c3236345c3231305c3030365c333136735c3231355c3333335c3030312b5c3336335c303230485c3330305c333036385c333731465c3333355c323532625c3234314e5c3335325c333637675c3236335c3233305c333631465b5c3230306e3c5c3333345c3336325c3335355c3033355c3137375c3033355c3232375c3333365c3333375c3235315c3335355f5c3032357e3f455c3234365c3333334f675c3234355c3331325c3232375a5c3233335c3032335c303330745c3230372b6a5c3031335c3031365c32313446495c3331325c3030323d3e5c3336315c3330315c3330325c3330375c3336335c3032345c3231345c3332335c5c493c5c3230335c3336375c3332323e5c333531245c3031335c3232335c3237305c3335355c3331305c3030376f205c3334335c3232335c3335355c3333335c3033372b5c303232255c3231345c333434205c3231345c3334345c303032513e5c3335315c3337317e555c333731795e393d5c3236315c3333335c3033372a475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336315c323533575c323235695d5c3233375c323133665c3337315c33313623385c3235335c3331375b485c3235355c3234325c3236365f5c3334365c3337335c3237365c3237355c3235355c323430475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731563856335c3232355c32313446725c303031315c3234375c3333355c3337335c3237372a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3233365c3337375c3030305c3332375c3336355c3337357e5c3237365c3032375c3336355c3337355c3137375f5c333630675c333233745c3333312f5c323537615c3236365c3236365c3230345c3031315c323435755c3231345c3031305c3332335c3335365c3232335c323634607c5c3237345c3235375c3033345c3233365c333030765c3330375c3331335c3336366f5c3330335c3033375c32303623465c3332325c3335356d615c323637525c3236365c3330305c30303728315c3232325c3234345c333537643b77295c3333335c3232325c3137375c3237335c3231365c3331355c3337365c3235335c3232315c3337355c3233315c3237365c3030314f695c3030355c3237375c3231335c3236355b315c3030345c333633475c33343658215c3231375c3337354a5c3030315c3233355c333337735c3233355c333432365c3030305c323334605c3031345c3337335c3234375c3332375c3237365c3032335c3336307a5c3333315c3231305c3236335c3031365c3032355c30333557285c3230342a5c3335357d5c323737215c3031315c32323420305c3334335c323134635c3236335c303032625c33363770745c323731235c3331365c333637675c3335355c333734235c3232335c3331335c3030355c323037785c3237325c3335325c3332335c3235315c3236355c333732475c3337365c3031365c3337365c3232365c3033315c3334315c3031375c3030364560505c3337355c323335575c3031365c3237335c323134715c323230325c3235345c3032332a426548525c303037385c3333335c3236375c3236335c303032625c3336345c3033353f4f5c303236422f5c333335475c3237335c3331335c333033385c3031325c3031325c3233355c3235305c323733465c303234645c3033355c323735785c333530385c3330365c303030345c3337353c595c3031305c323737755c3033365c3335372f5c3031345c333430282a765c3234325c3335355c303330515c323230765c3336355c3334335c3234305c3334335c3033305c3030325c333534715c323434315c323534715c32353044505c30323555465c3030305c3030335c3234305c3030325c3237355c3030335c3336345c3032335c3334316f5c333730285c3237375c3231315a6f5c3032335c3337304740555c3333325c3236365c3236365c3232325f3b5c3235325c3230325c3330345c33313320455c3033355c3031375c3033375c3237316c5c3336345c3335335c3337305c3235375c333037315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d5c3235335c3336365c3330315c333631325c3337305c3233375c3336365c3230315c3336312c5c3232315c323232615c323630785c3336345c333634705c3234305c3236325c3233305c333231435c3235305c333731795c3030355c3336375c3334345c3334375c3231347b7c5c3237362b5c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334365c3235335c3331335c3233325c3235345c3233375c3336355c3337355c3137375e5c3237375c3331355c3237315c33373621625c3236333a5c3336355c3032377b5c3137375c3334303a7e5c3233375c33323752385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3334375c3237375c3336355c3337355c3137375f5c3235375c3230335c3337355c3137375f5c3332375c3337345c3033365c3330335c3334315c3235355c3330365c3233375c3234355e5c3333355c3333345d5c3237345c3032365c3331345c303034485c3237335c3232375c3033305c3337315c333233214e5c333136465c303234735c3330374e5c3234335c3033315e5c3337313c575c3234315c3234335c3031355c32363736715c3232305c3336315c333437605c3334315c3030375c3335365c323736553e5f235c3334355c3335335c333333685c333434635c3334345c3336315c3033305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e5c333532585c3234374e2a295f5c3337325c3337365c3237375c3235355c3337365c3332332d5c3334325c3233344e575c3230365c3231365c3032365c323235385c3236345c3235375c3235335c3237355c333635775c3335305c333736475c323637275c3231325c33363434615c3236365c3334365c333136325c3033363c5c3335345c303334205c3337355c3332375c3331325c3234375c3331335c3334347c5c3237357b6d5c3033345c3231347c5c323032785c32353743465c3033336e6c5c333433215c3334335c3331365c3330315c3330325c3031375c3333357c5c3235327c5c323736475c3331335c3332375c3236365c3332315c3331305c3330375c3331315c333432315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237325c3337357a5d5c3232375c3336355c3337355c3137375d7d4f5c3336355c3334375c3033335c3337375c3030303e5c3234335c3337305c3337375c3030305c3233375c3336355c3336375c3033365c3333345c3233362b5c3332305c3332315c3230365c3333335c323333385c333130785c3336335c323630705c3230335c3336375f2a5c3233372f5c3232315c3336325c3336355c3335355c32363472315c3336325c3031315c3334325c3237355c303135586d5c3237315c3236335c3231345c3230375c3231375c3335365c3031365c3032307e5c3335335c333435535c3334355c3336323e5e5c3237355c3236365c323136463e4f5c3032315c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331336b475c3332335c3230355c3334365c3234376b6e5c3232315c333534325c3331325c3232315c3232335c303232725c3237312a305c3237372f2b5c3230315c3331315c3335355c3231365c3333305c3337315a5c3330365c3331324d2b2d5c3137375c3235375c3335335c3337325c3237355c3330335c3231355c3336315c333635245c3234315c303332515c3237337a6f5c3337365c3137375c3332375c3333347b5c333434505c3235365c333235785c3335355c323432415c3237363f5c3237305c323337707e5c3335335c3230355c3337355c3333372b5c3230315c3332375c3236365c3332315c3331305c3330375c3331315c3333365c3337305c3031374f2d3d5c3236323d5c323432225c3032375c3231305c3030305c3233315c303032315c3230365c3033375c323733605c3233315c3334335c303034715c3231365c303031385c30333377275c3032376d5c3234345c3331305c3331365c303034765c3236305c3235335c303134395c303231605c3335345c30313223242f5c3331315c333637705c3230375c3233365c323737285c3335315c3330365c333337545c333630265c323035255c323434705c3335345c32303161545c30303236465c3230345c3030305c3030324b5c3233345c3030335c3236335c323032385c3335335c3337355c3333345c3030335c3232315c3337335c3235375d3e5c3334375c3335345c333236765c3332345c3330355c3337355c3234357c725c3337365c3031355c3337306f5c3030365c3231336c5c3234325c3332325c333733592b5c303336225d5c3330312d5c3332372b265c3331375c3232335c3335365c32323242675c32313637715c3232315c3232355c3337305c333332385c323236335c3232315c3033305c3231345c3230325c303031285c323337775c3335365c3337345c3235335c3336325c3336325c323734727b635c3236363e5f465c3337305c3336335c333432755c333631375c3330345c3237354f5c333130705c3332365c3033326b5c3337375c303030675c33333334715c3232305c3032355c3032305c323030765c3030325c323737755c323333715c3331375c3033305c3033305c3335315c3231363c5c333436385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c333137626a5c3337334a5c3231375d3f5c3235375c3335335c3337325c3332375c3337315c3331375c3231305c3236335c3032375c323331665c3032335c3233327e5c3335347d5c3333305c3337322f5c33363377615c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3336325c3333375c3337325c3337365c3237375c3235375c3332375c3334365c3237375c3235375c3335335c3337325c3337375c3030305c3230325c3335302d5c323737785c3235335c3033345b5c5c5c3232305c3237305c32313132413b40555c333731795c3030375c3030335c3233376e5c3333305c3337317d5c3237335c3334315c3236375c3230335c333237415c3236335c3031362d5c3032375c3335355c3236325c3234365c3335315c323334215c3031355c3033305c3333305c323037625c3231355c3230305c3335355c3030305c3033345c323337555c3336365c3330325c3336305c3137375c3031343c395c3336365c323535505c333532265c3031305c333034565c3231365c323030613a3928305c323737272a5c303234645c3233365c3333305c303335315c3232345c3336366f5c3031345c3333305c3330353d5c3334312d6e5c3232302e5c3330365c3331375c3232375c3033315c3031355c3033305c3336325c3232345c3334317e415c3232355c30333346735c3231375c3237325c3030312b5c3231375c3232335c3333305c3330315c3332325c3236347d5c3235335c3337315c3033375c3236305c3336305e4e5c3234334d5c33343635565c323537485c3337312e5c3235375c3332355c3335345c3237345c3235375c3333345c3336365c3231375c3030345c3335315c323232655c3333356d426d5c333633415c3336325c3330375c30333541245c3031355c3230305c3230335c323035255c323732635c3030305c3032315c3336325c3230355c3231375c3335305c3231375c303037695c3337364c6d385c323035215c3337315c323435425c3032305c3336315c3336375c3232375c3030345c3031355c3230335c3030345c3334305c3334375c3033305c3330315c303330206d5c3031335c3033375c323132785c3030374e5c323032635c3331375c3232305c3235355c3232365c323137315c3330305c3032345c323030625c3033335c323137315c3230315c3336325c3232355c3030315c3236335c32313647545c3330315c3032315c3337335c3333375c323037624f5c3236335c3033315c3031325c3330365c3331365c32343760745c323137665c3030365c3330345c3030357e5c3335325c3336345c3333325c3030315c3336375e5c3231335c3231355c3235335c3335325c323435635c3336355c3030366a5c3330375c303332435c3033325c3330375c3033325c323034455c3030315554605c3030303a5c303030295c333234514c41455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c3030315c5c5c3335375c3330345f5c3032315c3231375c303130785c3031335c3330345a5c3333312c5c3031365c3233375c3234375c33313772362e5c3334335c32323542465c3030375c3332345c3031376f5c5c57455e5c3031315c3337336e785c32333478775c3334305c3032365c3234375c303030605c3236326a5c32323750585c3235365371396f305c3334335c3332335c3334355c3231355c3237315c3335355c3331315c3334335c32353567524e5c3032305c3232345c32323744795c3337315c323136235c3335325c3237303a5c3236355c3337375c3030305c3232362d5c3337345c3335355c3234315c3337315c3233305c333033745c33313729505c3235365c3331355c323237644e413b785c3033372f2a715c3331315c3335355c3231365c3333305c333731595c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337315f5c3335335c3337325c3337365c3237375c3334305c3337375c3030302f5c3337375c3030305f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314b5c3337375c3030305f5c3332375c3336355c3337325c3233375c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e525c3337375c3030305c3332375c3336355c3337357e5c3234375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c3237375c3336355c3337355c3137375f5c3235315c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3332315c3137375c3236325c3237375c3230304e5c3235355c3234356b5c3033325c3231315c3236345c3231355c333431795c3332325c3032325c3237337a5c303034405f665c303237385c3031325c3337375c3030307b5c3333335c3033345c3032305c3031327c5c3335315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3336345c3234335c333636525c333730615c3031365c3233355c333630335c3330325c3336325c333135696c255c3237355c303137793e5c3332365c3337335c3331305c3335355c3336325c3230315c3336325c3031345c3032305c323334675c333330743b4c7e5c3230365c30313173545c3237375c3232375c3336355c3337355c3137374f5c3335365c323730375c3031375c3335355c3236333f685c3332375c3330315c3032365c3337366f4f5c3332355c3337375c3030305b5c333633365f5c3031375c3336365c3331376e5c3335376c5c3231307e695c3236375c3330325c32373731515c333136575c303132315c3230335c333436655c3230374c645c3030355c3330325c3231305c33373543405c3336305c3332375c333636545c3332315c3330375c3030355c3235343b5c3331335c3235305c3337355c3333375c303034305c3031365c3234305c3235305c3333325c30313038555c3033305c3331305c3330365c3332335c3331325c323234262e5c3331325c3333375c333031295c3032345c3232305c333130615c32363757593733465c3333334e385c3337335c323434205c3330315c3033317e463b602f5c3331315c3334355c3335355b695c3031335c303234705c323533475c303230202b335c3230354c5c3235332f5c3232375c3336325c323134205c3030345c3033355c3230335c3233365c3031305c3330305c333036385c3333335c3335365c3233375c3237335c3033367d5c3336315f5c3334323c5f5c3030373e5c3033306a5c333336245c3232362b6f5c323636435c3032305c3230325c33313124425c323036495c33333523585c33323028452c385c333133635c303334467e5c3335305c3033304f5c3331325c3237335c3335335c3237315c3236352d465c3335325c3337365c3335305c3232375c3237335c3237315c3232345c3331333c5c333031392e5c3330345c3032335c3231375c3232335c3232307b5c3233365c3333305c3335355c3231375c3232375c3335312f5c3333335c3231335c3334325c3334325c3337305c3330335c3330375c3336315c3337304b4c5c3232305c3031355c3032335c333033675c3331315c3232335c3331315e5c3033325c3335305c333430385c3033372f5c333335515c3336325c303337425c3235375c3337307c5c3331315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3330305c3330355c3332355c3334375c3235315c3331325c323636475c3334305c323734595c3233315c3337355c3137375c3033345c333531415c3337335c3232345c3336345e6f5c3235335c3337353e5e7a5c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446725c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e5c3033335c3337375c3030305f5c3332375c3336355c3337325c3337344f5c3336355c3337355c3137375f5c3336307a5f5c3230375c3233325c3033315c3332343c475c3030345c3231336e5c323736555c3236332c5c3232325c3335354e5c3032375c3232345c303031415c3333315c3331305c3335315c3331375c3337333d5c3236315c3232355c3337325c3032375c3330335c3033322c725c3331335c3232325c3236305c333030555c30313064405c32373720295c3230335c3236305c3232355c3030305c3230315c323634755c3330374c5c333435425c3232365f345c333730735c3334315c3333375c3335345c3231355c303135666b445c3231365c3334325c3334325467605c3234372a5c3237315c3231376a5c3235375c3335365c3337365c3335365c303036735c3333335c303335463e4f515c3336305c3330335c323133475c32303772455c3032305c323135435c3033305c323432425c333035365c3234335c3033345c3234315c3031325c3031365c3032375c3033365c3235335c3333305c333435715c3237317e5c3231335c3031354d425c3233325c3336333f5c323431785f2f797e5d5c3033365c3137375c3231327e5c3336335c3337315c3335345c3237365c3335375c3330365c3334375c323636685c3333324a475c3234325c3333355c3331365c333336485c3232352c5c333434625c323436205c3231345c3032375c3331315c3330315c3330305c3333315c333333625c3334375c323030785c3331375c3331325c3032375c3334345c3337345c333434585c3232363625635c3032315c3336325c303031285c323337775c3335365c3337345c3235335c3336325c3336325c323734727b635c3236363e5f5c3237355c3334345c333631295c3236305c3336305c3330365c3235315c3031345c323333576d5c3235345c323431485c3231306e5c5c46542a5c3230305c3234335c3033375c3330364f2b5c3230325c3234345c3337345c3234354a5c3330375c333630425c3330345c3236315c3236312b5c3033305c3231375c3232305c303131445c3337335c323737775c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c333631635c323634713e3b5c3231375c3033375c3237375c3230375c3336345c3232375c33353024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3334355f5c3337325c3337365c3237375c3235375c3332375c3336325c3237375c3335335c3337325c3337365c3237375c3334305c3335317863655c3234375c323130745c33333144615c3030325d455c3237335c33313340765c3337345c3331315c3336325c3235375c3331335c3331325c333430755c3335355c3231365c3333305c3337317d5c3332322840505c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336327c5c3337375c303030615c3236365c3332325c3335365c3033315c323032797b24524c4b5c3331325c3337355c3333375c3232357e515c3232355c3334335c3235376c765c3330375c3331335c3336345c303034505c3030305c3235325c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c3331315e3a5c3336365c333332395c5c7c5c3233365c3331365c3030355c3333365c3031375c3337325c3337365c3237375c3235375c3233375c3335345c3033345c3031313b5c3332325c333034435c3236335c3231335c3337335c3332335c3337375c3030302f5c33353373575c3330335c3032315c3233305c3335375c3231345c3232315c3333335c3235355c3237365c3333305c3333355c3230315c3231355c303130685c3231305c323035705c30323479605c323230365c3336355c3335355c323634725c3237305c3337313e5c3230335c333630233a4a5c3235355c3232305c3235305c3234315c3331315c3232365c3031305c3336305c33313056205c3030365c3032375c3331335c3033312b5c3230335c3232335c3330365c3031325c3336354e5c3232315c3337345c3334375c3234335c3330305c323032665c3137375c323632225c3031355c32343462315c3236305c3234315c3336325c3332335c303031725c3230332b5c3330305c3331375c3337335c323430715c3332317e5c3230345c3336304a5c3236345c3230345c3331315c333434475c3237315c303232555c3031365c3236315c323035655c3333335c3033325c3230305c3030305c3032315c3337375c3030305c3236335c3331315c3334335c3030355c3030375c3333345c333036235c3336345c3337345c3331375c3332345c3233315c3336342f5c3230375c3030362c5c3233375c3232343f305c3033315c323135365c3031365c30323146315c323635795c3033305c333332785c3335325c3031375c3333355c3330365c3330355c333235655c3031365c323435485c3030345c3032315c3230325c3031356378655c3334346b465c333134685c3235315c3237305c32353121765c3032305555405c333030505c3031375c3030305c3230335c3333345c3032315c3231342f285c32333355445c3233375c3232345c3137375c3236345c3230375c3330315c3333317e5c3031355c333734505c3332346c235c323033665c32323179215c3237325c3332335c3334365c3231362c5c3030315c303133305c333034635c3031315c3231375c3232375c3033334e3a60745c3033305c3330375c323235475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c333735715c3337305c3332335c3336305f425c3337305c3333335c333431375c33323235655c3336322e5c3234325c3331345c3232365a5c323134485c3031345c3236365c3236327a5c3231345c333635535c3230305c3033317b5c323137425c3032355c3230375c3334364f5c3330355f5c3230325e255c333730315c3235373d5c3231365c3237315c3234375c3033305c3234302d5c323130355c303133685c33313341305c3334335c303032365c3333315c33313021795c3030375c303034635c3234305c303030635c3334375c333631345c30333529392d5c3233375c333635635c3336303e235c3331305c323532655c3236355c3334355a5c3232325c323735293d5c3033376f275c3337325c3137375c3233355c3335375c333032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323734375c3337365c3237375c3235375c3335335c3336355c3337305c3237375c3335335c3337325c3337365c3237375c3334305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3137375c3335335c3337325c3337365c323737535c3337325c3337365c3237375c3235375c33373024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e555c323136255c3231345c3334355046415c3030305c3233305c3332335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3234355c3337375c3030305c3235375c3335335c3337325c3337354f5c3335335c3337325c3337365c3237375c3334305c3336343e5c3033345c3336315c3231355c3335375c3230375c333336355c3333325c3236335a5c32343328684a5c3030335c3236335c3030353e546d5c3233315c3330375c3331325c3030367b635c3236365c3030365c333337545c3336305c3337365c323631675c3235375c3333327d5c3234365c3331325c3031305c3332302c5c3236315c3235335c3330365c3032335c3031355c3032315c3337355c3332375c3331323f775c3331325c3334317a5c3337375c3030305c323632395c3033305c3337313c2a385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372e5c3231375c32303775475c3336305c3335365c3234375c3032355c333434285c3032302b285c3232315132315c3232345c3337315c3030375c3331335c3331325c3337345c3234335c3233365c333333474c7c5c3237355c3337307c535c323033515c3232335c3237325c3337365c3237375c3235375c3335335f5c3236375c3331305c3237305c3233335c3032315c323237545c3231352c445c3233345c323531795c3335325c3334335c3334365c3237375c3331335c3335365c333237575c3335365c323631405c3030305c3031365c3232365c3236315c3330355c3336335c3330375c3330325c3234315c3033333f5c3332357c5c3235335c3337335c323736575c3231365c3237355c3236365c323136575c303337245c3336365c30333362605c3337375c30303066585c3230375c3031323646735c30333656305c303235465c333030765c3336315c3331313d365c3231345c3336345c3330325c3332325c3332335c3234355c3230365c3337325c3332325c3033335c32373368225c3032313b4641445c3337335c3230335c3336375f2a5c3337365c3335375c3232315c3336325c3336327b6d5c3033345c3231347c5c323233455c3030305c3030315d2d635c3231335c3334375c3231375c32303542365c3137375c3235325c333731575c3336377c5c3235375c3033357b6d5c3033345c3235363e4f713b5c3335325c3231375c3333365c323431385c3332345c3231325c3232345c3033355c3332335c3337345c323137685c3336302d5c3336344b225c3335365c3032315c32343165605c3234365c3033305c32313057667c657e515c3332376124715c3230305c3234375c3235305d5c3236317d5c3033375c3334305c3231335c3335305c303034515c3231355c3232315c323431264c34315c3334315c5c5c3236335c3235305c3331305c3033335c3030315c3033315c3333304f50305c3031363852235c3337315f5c3334315c3334365c3336355c3231365c333332265c323135205c303031625c3030322d5c3233335c3232305c323337305c3232335c3334355c3233372f5c3337355c3231365c3237365c3232315c3336365c333036635c3337324b5c3330305c3336326e5c3231325c3333315c3031365c33323562555c323130685c3231315c3031355c3233315c3137375c3230345c3335345c3330367e4c5c3337355c3032335c3235375c3030305c333035486c5c3336345c323532285c3234325c323331275c3330345c3137375c333630515c3233375c3032335c303233755c3334305c3333375c3031375c3330365c3337305c3031305c3236335f4e5c3032345c3030325c3333345c3236325c3234347c605c3233347c5c3236325c3334345c3336315c333732647c555c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3333365c3237376d5c3137375c3032335c3231375c3032327e5c3332305c3033325c333034695c3331345a5430695c3335312a5c3235364f5c3031325c3033355c3230305c3337317a6f765c3030345c3334375c3231355c3237355c3137375c3237335c3334305c3236315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e6b5c3032312e6a5c3236325c3337365c3237375c3235375c3335335c3334375c3337345c3334315c3330345c3033305c3233375c323535665c3232355c3334375c3333315c3333335c3337375c3030305c3030315c3332335c3336345c3337365c3237325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f355c3337375c3030305c3235375c3335335c3337325c3337357e7b5c3337325c3337365c3237375c3235375c3337303d5c3232375c3330325c333135335c3331355c3332375c3234345c3237305855455c3237325c323436765c3234375c333335255c323230617e4e465c3030315c3334375c3337355c3233365c3333305c3331325c3337325c3337365c3232336a5e625c3332315c3333322261795c3031305c3230345c3032345c3033365a642f5c3331305c3234345c3235365c3032375c3232335c333333685c3336345c3330325c3337315c3334375c3330326d30435c3234365c3333355c3333355c3235355c323732295c323232785c3334332c5c3032335c3335365c333535315c3336305c323737215c3331325c3336335c3331315c3334335c30333347235c3033314f4e5c3336305c3237365c3233375c3032355c3331355c3337305c3031355c3030325b5c323531525c3031365c3330345c3330315c323134794b5c3330325c3334355c303036546d5c3033315c3331315c303337745c303032575c303337275c3332305c333431572d5c3032345c31373742705c3233365c3033375c3333305c333435345c3333335c333336575c3232375c3333365c3337375c3030305c333131235c3333323c5c3032355c3234355c323730565c3232363b65425c3031345c333132563f40545c3334375c3033335c30303638525b5c3033305c33303630405c3333325c3032363f5c3234337c256a5c3232305c3333325c3032325c3232365c333631205c303137275c3331365c3032376b5c303032765c3334345c3030315c32363475205c3334375c3332305c3235305c3033305c5c6c4f5c3031365c3336305c3033355c323034572d5c323237305c3230365c3337315c3234325c3031345c3232305c3230352a5c323736505c3030375c3033315c3231345c3031375c323237605c303037385c3334357a5c3234365c3031305c3231375c333337345c3033335f2a5c3333345c3236345c3232315c3234305c323234602b5c3031305c3236365c3032305c3234355c3032335c3231375c3237305c3237365c3231325c3031375c303335575c333730715c3236357b5c3031375c32353435685c3234325c323132605c30323451455c3030305c30323451455c3030305c30323451455c3030305c30323451455c3030307c5c3033355c3337375c3030305c3030355c3032355c333631395c3237315c3336315c3230375c323035345c3030355c3331304b2b392f5c3033355c32323572732c5c323031405c333530785c333034273e5c3233315c333734475c3330375c3336315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d5c3232335c3336365c3236375c333631285c333631475c3335355c3030315c3334325c3235315c3232355c3236374565325c3335315c3335305c3331325c3234305c3232355c3336325c3332355c3032355c323234614e41705c333331395c3334335c3234376e3c6e385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3331345c3332375c3233373d593f5c3335335c3337325c3337365c3237355c3137375c3233325c3336335c333134435c33303566555c3335325c313737795c3235375c3232325c3332317e5f5c33323752385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3334375c3237375c3336355c3337355c3137375f5c3235375c3230375c3337355c3137375f5c3332375c3337345c3033365c3337375c3030305c3334315c333032415c3234315c3335315c3033325c3232365c323537715c303332455c303030785c3234335c3331304e41525c3230345c3235327c5c323337303c7a725c3234335c323436325c3233307e245c3336315c3230355c3330365c3237325c3335355c303334715c3031335c30333330405c333632605f5c3336375c3030305c5c5c3335345c3033335c3232375c3031325c3237374d5c3234335c3332306d5c323037545c3331355c3231365c3230335c3234345c3333305c323130565c303030415c323732765c323131335c3232325c3334342a5c323030765c3031345c3231355c3235315c3230327b635c3235375c3033305c5c285c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323735535c3235352e45493d3f3f5c3335335c3337325c3336335c3337325c32333476695e5c3231365c3032325c32333657464e305c32313457375c3233335c3232375c3237345c3332335c333632575c3236355c3237365c3337335c3335305c3032315c3330345c3236315c3233345c3231305c333034645c3032305c303131445c3337335c323737775c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e5b5c3337375c3030305f5c3332375c3336355c3337325c3337345c3236375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446725c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5d5d5c3030375c3330325c3232375c3333325c3333345c3237305c3236325c3236345c3333325c3234335c3030315c3234365c3031315c323034435c3336325c3231355c3234305c3335345c3334345c3033365c3030313d5c3236315c3333305c3031375c3232365c32323272765a5c3337375c3030305f5c3332375c3336355c3237365c33323468555c3330345c333135535c3234335c303237293e5c3231335f5c3335335c3337325c3337315c333436436e5c3030335c3230305c3232316d62425c3337365c33353532415c333731465c3332355c33373179535c3230315c3232335c3335355c3333335c3033372f5c3332315c3333375c3236335c3337375c3030305c3335345c3333325c3333325c3233355c3335355c3236365c3236355c3334325c303130225c3231315732415c3234375c3236325c3231365c303331425c323334495c3232345c3330365c3333342e5c3031303d315c3336336d5c3330315c3031335c3331375c3337343c5c3336303d5c3232375c3230356e525c3336355c3235355c3332327b5c333434535c3231315c3331325c333535305c323731455c3333335c3334355c323036415c3330305c3337365c3336375c5c5c3234305c333031535c3330325c333735595c3334302d415c323535405c3232315c3232325c3032355c3231315d5c3231316d5c3230315c30333032465c3032355c3030305c3330325c3030335c33353470415c3030345c3031375c32373046235c3336362861395f354d5c3331375c333237722e5c3032325c3337325c3237345c3334335c3231315c333134355c323237485c3335365c3232375c323537765c3237336d5c3335327b575c3230363c39696d5c3033325c3237345c3032305c3330335c3032322e5c30323331465c3032345c3031355c3234355c30333028535c3033305c3330365c3031365c333430715c3231345c3032315c3231342e5c3030325c3330375c3332325c333033656f6e5c3330315c3234325c323032385c3231305c30333341445c3030335c3030335c303030635c333632555c3033375c3336305c3032315c333531595c3237365c3033345c3333342d5c3231305c303032264c5c3334305c3236322e5c3331345c3032305c3231305c3030325c333433625c3334375c303330205c3233365c333035715c3230315c33363753625c323735435c3336345c3332305c3235325c3337325c3230355c3335345a6d5c3231355c3331355c3333345c3335355c3236325c303130236964635c33333154645c3233375c333130555c3231325c3336335c3031375c333332675c3330345c3330335c3330325c3137375c3030325c323734617a24315c3331332d5c3232335a46555c3336365c3236365c3335315c3231305c323130605c3334305c333632375c3232335c3330375c323437515c333234445c3334355c3331315c3032372e5c33303736265c3236325c3330335c3332305c323531595c3335355c3032345c3333375c3333345c3235367e585c3337305c323237556f5c303230785c323333565c3332355c3333363f2e5b5c3335335c3331312e5c5c5c3234325c3031345c3235333b5c3030362a305c3230305c3032355c3336353d5c3236315c3333335c3033372e5c5c712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e55485c323236335c3232305c323032335c3232305c303131445c3337335c3234375c3334355c333731575c3334355c333435785c3334345c3336365c3330376c7c5c3235315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334356f7e5c3237375c3332375c3336355c333735775c333736595c3232345c3233345c3233336d5c3335325c3337375c3030305c3235375c3335335c3337325c3237315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3235335c3337375c3030305f5c3332375c3336355c3337325c3235375c3335335c3337325c3337365c3237375c3334305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3137375c3335335c3337325c3337365c323737535c3337325c3337365c3237375c3235375c33373024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331325f5c3337325c3337365c3237375c3235375c3332345c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3332325c323737675c3137375c303130375c3231323e265c333331445c323236493c365c3236314973705c323031705c3032315c3030325c3030353b4e5c333136405c3331325c3233345c3336355c33373147235c3033315f355c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336355c3336375c3337345c3032335c3337335c3334315c3337347a5c3330355c3330375c3231325c3336355c3233315c3235356131435c3336367b355c3331305c333036375c30303264543b735c33363742735c3337305c3031345c3032305c303132745c3334315c3234335c333137562b5c3337325c3337365c3237375c3235375f5c3234315c3334315c3337343f5c333236734a5c3032305c3335345c3335375c3337375c3030305c3230305c3335335c3337325c3137375d7d5c3030325c3033375c3230375c3234345c3236345c3030355c3235345c333431255c323633236c5c3033305c3333345c3230335c3335375c3032355c3330325c3031365c3233375c3237345c333434715c3330375c3030317e5f2a5c3336375c323134203e5c3030315c3337305c3137375c3235355c33353373465c3235337165645c33303554475c3236305c3235345c3234354c685c3234305c3231305c333237237c6b5c3232305c303036705c303137405c323437675c3237345b5c33373025225c3232325c3033315c303134365c3335325c333533265c333436685c333333695c3330375c303337745c3230345c303330232f5c3331305c3330376c5c3030355c3337313c5c3237375c3233373f6e5c3333315c3032335c3330335f5c3030375c3336345c33333338765c3330352e5c3234355c323530455c3032345c3235315c3033325c3231345c303035545c3333365c333035425c3234305c3033345c3236322e4f5c3033357a605c3031355c3233365c3337355972535c3232345c3232315c3337335c3332366b5c323131784c5c3030356a5c333133755c3032376f5d5c3232375c333433635c3334305c3031355c3237375c323734695c3031325c333535725c333033732a5c3334345c323032765c3336303e5e545c3334335c3232335c3335355c3333335c3033372b635c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237372f5c3137375c3335335c3337325c3337365c3237375f5c3334364f5c3335335c3337325c3337365c3237375c3334305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3331305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323633585c3333315c3231315c3235365c3234325c3231315c303230445c3331365c3335335c303336634c5c33353527685c3333325c323737285c3331325c333630327b635c3236363e565c3236355c3332335c3337325c3337365c3237375c323537565c3232335c3232335c3334355b5c3237375c3335335c3337325c3337365c3235375c3335345c3233365c3030365c3332315c3137375c3236327c37665c3234325c333332345c3232315c33333125725c3235315c3230325c3234355c323134475c3030335c3336377c5c3231345c303030335c3337365c3330305c333435715c333632775c3333365c303131554b5c3237375c323235235c3236375c3337315c3332355c3237345c3234355c323137695c5c435c333235585c3234325c3334302e3a5c323232315c3330375c3331345c323733725c3233345c3334345c3032365c3335335c30333468525c333236385c323030685c3330365c3032363c6c5c3033375c3237325c33373154795c313737775c3031335c3332375c3236365c3332315c3331325c3334335c3334345c3333355c3336305c3231335c3033302e5c3231365c3333305c3232365c3333323f5c3336355c323034455c3032375c3331355c3033315846367e5c3335345c3032325c3030305c333137395c3033305c3330305c333435715c3336327d44225c3234335c303336545c313737545c333431705c3336315c3330325c3332305c3230365c3033363b45255c3336372f5c3331345c3337322f5c3334315c3337305c32313374665c3032375c3231346d652e5c323436205c323434325c3330355c3230335c3236355c3236362f5c3031335c323136795c5c5c3033365c3335315c323633295c3335373a595c303337605c3230315c3030325c3232345c3336325c33343345205c3234315c5c7c5c3234305c333630365c3235375c323537603d30315c3230315c3336335c3337375c3030305c3330335c3337315c3237345c3232355c3333365c3331375c303331585c33333776235c3230305c3230365c303031225c3335355c32303452365c3334335c3030375c303035795c303335535c3033375c3237335c3336375c3331355c303236445c3232325c333032305c3231365820545c3333325368425c3032345c3030325c3234335c3334355e5c323037395c3334335c3230335c3232315c3230315c3231345c3031354d5c3331335c33363451455c3030325c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c3031325c3337305c3233335c3337365c303132335c33343260655c3336306f5c3230375c3334335c3232305c3230325c3234326b5c3335315c33323540275c3232325c3235315c303337627071283d3f5c3235325c3337355c3236335f5c3233315c3237375c3236365c3337375c3030305c3231315c3337375c3030305c333431225c3337305c3337375c3030305c3235315c3330305c3031365c3335305c3236347b68345c3336345c32323157247c5c32343256515c3336325c333632374a5c3330305c3233345c3336315c3236375c3333335c3231362c645c32373169355c3333345c3337305c323336305c3330347b5c3033345c323536505f6d5c3234355c3337325c3337365c3230375c323030475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237373d5c3137375c3335335c3337325c3337365c3237375f5c3330315c3137375c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3237335c32343268735c3335325c3336375c3235336d675c3031325c3231315c3231375d5c3235335c333032705c3237345c3030335c3236375c323235385c3030305c3233365c3333365c3333305c33373169475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3335377e5c3032325c333531635c333535775c323637625c3032355c3033365f5c3232355c3033375c3031315c3330325c3232325c33353048535c3334355c3233345c323134205c3334375c3231375c3330335c3033315d5c3335305c3330335c3333325c333135455c3237355c3337375c3030305c3235375c3335335c3337325c3237375c3236315c3232335c3334305c3234335c3233305c3334335c33353161665c3333355c3234345c3336355c3336344a5c3335375c3336305f5c3332375a5c3032365c3333375c303132755c3234375c3031345c3332315c3330315c3030344463383b485c3334317e555c3331325c3031345c3230325c3030305c333131385c3330374e315c3230355c3333355c3332315c323737676f5c3032366a5c3330303d5c3234355c3237355c3232325c333435775c333435665c3030335c30303060605c3033355c323337745c3335355c3330364e3a715c3336374e5c333337465c3332322d4b5c3331325c3331355c3032355c323332215c3031335c3232325c3032315c303130285c30303468485f5c323231495c5c2f275c3236365c3332315c3335315c3230355c3336375c3237375c303033695c3232315c333535765b65505c3030345c333331285c3031325c323230425c3230335c3330305c3031315c3335325c3031365c3335365c323337745c3030325c3032335c303333635c3336355c3237365c3234374d6b5c3235315c3337325c3336335c3334305c3237345c32363355797d5c3335335c3337345c3231375c3233345c3236345c3335375c333330735c333432555c3334315c3030365c3031335d2e3c5c323032775c3031335c3232305c3030325c33343368285c3031375c3232375c3332335c3230305c3031367078235c3235325c3232305c323637225c3337355c3230323e275c3234305c3333345c3236365c333732344d5c3330375c3031317832385c3033345c3031375c3333355c3336345c333731475c5c5c3033365c3233305c3337375c303030675c3336345c3033335c333032565c3235315c3031355c323431296f5c3033325c3030305c333632655c3330325c333535604e5c3333345c323030365c3231365c3234345c3033345c3337325c3032355c3030335c3031335c3231355c3231315c33323053582a765c3332355c3236315c3137375c3235315c323331675c3336375c3237365c3337375c3030305c3337305c3030375c3334365c3332343f5c323630475c3330345c3334345c3330335c3031337d5c303332235c333036425e5c3031345c3231365c3030375c3030335c3336377d3e515c3332375c3030375c3234363f5c3333315c3337355c3032325c3336305c3330365c3231315c3031375c3230365c323734375c323435695c3032365c3336315c323434365c3336365c3032365c3232315a5c3330375c303334785c3333325c3235325c3231305c3032345c3030315c3230305c3030365c3030305c3033355c3230305c3337325c3031325c3332335c3234325c32373229505c3230355c3032365c3333347a5c3233365c333436595c32323261325c3233314e586b5c333336565c3237355c3333355c3336365c3031325c3336336f5c3333325c3032335c3334325c3236327c5c3033345c3337305d5c3235326b5c333132505c3335322d5c3231335d3e375c3030345c3230365c3237307c5c3230355c3334335c303037214067235c323730435c3331305c3335335e5c3232335f5c3233335c3333375c3236365c3335375c3330355c3331375c3337304f5c323736275c3233355c3030365c3331315c3230315c3332323c365a5c3332344b5c3033375c333134645c3237306d5c323436535c3336377a5c3030325c3030325c303336785c3336325c3331315c3331373f2c5c3334322a5c333733285d6e5c333134385c323037335c3337365c3331335c3330305c3331325c3234345f5c3237372d235c3335335c3333375c3334355c333736475c3331365c3236335c333133255c3333355c3333345c333237535c3232325c3332375c303233485e59715c3237315c3231335c323636335c3230335c3236375c3334365c3030375c3237337b765c3330375c3331335c303134712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334365c3335375c3337355c3137375f5c3332375c3335335c3337345c3335325c3333355c3337375c3030305c3235375c3335335c3337325c333734485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237325e5c3033325c3332305c333333575c3332366d6d625c32313150345c323132252a5c3237305c3333305c3233372e5c3334305c3237304e465c3030375f615c3331305c3330365736385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f655c3336305c3337375c303030535c3332323c3a5c3236375c303237374c5c3236315c3333345c323733226d48495c3336325c3332345c303234385223395c3030376f5f5c333636575c323436325c3233335c333231515c3232345c333237335c3332335c3337325c3337365c3237375c3235357d7c5c3234365c3230355c3031344e365c3233343133515c3230355c3335365c333333692b2e5c3233325c3237365c3237337c5c3337365c3337375c303030535c3230325c333335515c3032345c333037695c303334203c635c3031315c3033363c5c3236315c3337335c3235375c323235475c3232375c333637705c3237357b6d5c3033345c3235363e4d3b7b5c3232335c3031355c3237324220485c3234325d5c3235325c3331335c3033325c3032335c3236315c3236305c3030325c3235327c5c3234332b5c3336335c3033345c3232315c323030315c3331305c3334305c3334335c3231305f5c3033375c3335305c3032315c3233345c32353322615c3332335c3337355c5c5c3031355c333632635c3331335c333731575c3336375c5c5c3235375c3331315c3332375c333331795c3033305c3337315c3030355c3336315c3337365c3230315c3033315c3331325c323632265c3033353f5c3332355c3330305c333337263c5c3237375c3232355c313737755c3331325c3337345c3233357d5c3232375c3232315c3231375c3232335c3333355c3336365c3336345c3237375c3233315c3033375c3332305c3137375c3333335c3033316f4c443f5c333630255c333736675c3234316a5c32373626685c3336345c3031354a335c3033336c6b792375585c3330325c3230305c3335345c3031315c3031345c3234302f4e573d475c3331335c3332345c3032345d5c3233372e5c3234344b5c30333125635c3032315c3336325c303031285c323337775c3335365c3337345c3235335c3336325c3336325c323734727b635c3236363e5f575c3332347c735c3234315c3331315c3234375d5c3330375c303131455c3232315c3232376a5c3231305c3334316f5c3232345c3334315c3030365c3332353e572b5c333632753e5c3231335c3331325c3334335c3334345c3336325c3230345c3231316339585c3330347c5c3230304a275c3333355c3337335c3237372a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3331345c333036545c3231345c333334795d5c3331375c3331325c3337305c3331375c3032375c3230375c3330355c3332355c3234325c3336305c3336355c3032345c3332324e5c333636695c3336365c33353424712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3334375f5c3337325c3337365c3237375c3235375c3332375c3336335c3233375c3335335c3337325c3337365c3237375c3334305c323534712c672b5c3033305c3231345c3230325c303031285c323337745c3337345c3237372a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3335305c3033335c3033305c3336375c3333325c3330312a5c3333335c3330345c3237315c3336325c323131285c323337775c323130785f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313e7d5c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3335365c3333365c3033315c323134365c3230315c3234365c3331305c3236365c3336315c3235375c3335365c3234305c3030345c3234325c3031375c3232375c3334355c3230345c3032305c3237305c3231375c3232355c3337317a5c3336365c333332395c5c7c5c3233365c3235365c3030355c3337344b5c3332335c3337325c3337365c3237375c3334315c3337375c303030515c333430495c3333325c3236357877515c313737735c3137375c3334366c5c3335315c3232305c3235325c3331335c3237356d5c3234335c323034635c3033372a5c3335355c3333315c333632475c3336325c3235375c3331305c3237315c3033345c3137375c3334335c323430765c3330325c3337335c3236375c323033225c3032315c3333335c323630365c323231445c3030335c3331315c3231315c3032335c3030305c333632475c3030335c3334345c303335765c3334355c3230375c303330205c3031345c3031346d4f5c3030375c3332335c323231625c3232335c3331345c3032365c3331315c3031305c3330305f5c3232315c303130295c3232355c3231345c3030355f5c3232305c3032325c323734724f4d5c3234335c3332335c3031335c3335355c3233365c3030365c323232295c3033305c3233305c323432445c30333364605c3332315c3231375c3232345c3230325c3334305c3030323e415c3231345c3335353e5c3230305c3334335c3030307c5c323733635c3336355c3236355c3237365c3230375c333534565c3236365c3236363e5c3233315c3336305c3234345c3031325c3232365c3234355c3232365c3031305c3232305c303037715c3237342e5c3332365c3030375c3334355c3331305c303033685c3336345c3334375c3332305c3235305c3033305c5c6c4d5c3337325c3334355c3237345c3032345c3335306d5c3336305c3232365c3236312a315c3232315c333232785c323036545c323032575c323030425c3031365c3237305c3030345c323136395c3030305c303030365c3232355c3231375c3235315c323533255c3335335c3235335c3031325c3331365c3332375c3337343d5c323436785c323533495c3237305c333233355c3231335c3031337d4b4f5c3237305d5c3236325c3333335c5c5c3330365c3033355c303330765c3334305c3336375c3030375c3232307b5c3033366a465c3332345c32303453435c3032345c3331335c3236315c3333375c3334353b435c3232315c3237375c33343538535c3236375c30313430495c3331375c303334295c3334335c3230365c3333335d3c456a7c5c32373732445c3231372b5c323331335c3237335c3334346e385c333435475c3030335c3334375c333131385c3330365c3330365c3331305c3337315b695c3237315c3032325c3231325c323232715c3232325c323732675c3331345c3233375c3032335c3137375c3334305c3233375c3237365c3032375c3332375c3234365c3232365c3337335c3330315c3232375c3335375c3334317b5c3236377d5c3330365c333136485c3330345c3332365c3237305c3334332a5c3237375c3330365c3233315c3330375c3235335c3031365c3030305c30303060635c3334354f5c3231305c3333375c3236325c3335375c3330345c3031375c323035455c3234365c333234345c3030365c3237335c3236305c3030305c3236315c333234347537305c3234305c5c5c3030335c3233355c3235315c3237315c3032375c303030725c333431785c3033365c3333372f5c3335325c3232355c3230355c3335325f5b5c3231315c3032375c3230335c3332315c3230305c3031355c3230305c3333305c3334345c3031345c3230304e5c3031375c3033353a5c3230325c3031365c30313020585c3335335c5c3530745c3334375c3235325c3332305c3337305c3331345c3330335c3230345c3236325c333734655c3334354d7b39796d5c3336376d5c333637585c3337345048444722315c3033315c3030345c303032513e5c3335375c3333355c333731575c3334355c333435785c3334345c3336365c3330376c7c5c3235315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3336356f5c3334323f5c3335345c3330355c3336305c3335375c3334326a4b265c3234315c3234305c333033615c3235305c3331305c3030375c3337344c5c3236345c333035582e5c3030375c3334325c3030365c3332365c3331374f5c3233305c3033365c3230335c333230635c3334335c3333375c3231335f5c3236305c3232375c3231325c3237345c3030355c3032355c3332365c3234375c3334315c323131635c3336313e5c3232335c3033315c3333355c333435415c3032304b5c3333305c3232335c3231363c5c3236305c323434385c3330325c3230304a5c3233355c333335305c3234307d5c333337365c3234365c3032325c3235345c3032355c3336375c3337365c3237375c3235365c3337375c3030305c3334375c3337315c323736635c3330325c3233305c3337345c30303275205c3237355c3234345c303237555c3237375c3331356f5c3336375f5c3337345c333736665c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435795c323635365c3232325c3237323c265c333336446d5c3231365c3234323c5c3032343f285c3333323e5e475c303330275c3236363b635c33343564712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e5c3033335c3337375c3030305f5c3332375c3336355c3337325c333734675c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c3237375c3336355c3337355c3137375f5c3235315c3337355c3137375f5c3332375c3337345c303337505c33373053775c3334365c333531735c33333279495c3237325c33333664615c3230345c3334355c303033327c5c3235335c333632725c32373721245c3336365c3330305c333434632b5c3333335c3330335c3030325c3334303a5c33333324437c7c247c5c3234375c3337325c3235375c3232355c313737775c3331325c3336315c3331315c3335355c32363472315c333632795c3231375c333032585c3336366a5c3236375c32303120403646585c323532725c323034495c3033375c3031335c333632725c3237305c3033355c3137375c3333315c3033345c323134657d525c3330325c333234335c33353748525c3333335c30333379455c3330314f5c3232363f5c323231725c3230332a425c3334305c3233365c3237345c3030315c3330315c3033305f5c3234315c3330325c3237366a2b5b5c3233375c3332305c3337342d5e555c3336325c3233324e5b5c3330365c3335335c3335367a7e5c3033325c3033365c3232335c3336305c3337325c3030345c3230363b55545c3231365c303236295c3032325c3233305c323034395c5c5c303131495c3030315c3033335c3331335c3335355c3236345c3233375c323432755c3033305c3331345f47785c3030365c333231215c3236375c3236355c3032312c715c3235365c303231447e485c3337335c3234325e5c3030325c333431385c3335315c3233345c3336345c3330325c303336785c3331345e5c3033335c3334307d3d5c3330322e5c3336305c3237337e675c3032325c3330355c3033305c3333305c3330375c333134565c3334335c3334345c3330305c3331365c3030375c3033345c3032315c323134645c3232355c3330345f465c333730325c333132685c3233305c333537455c3230305c3334315c3236325c333630475c323034243a5c3335365c333036575c3231345c3334306470474f5c3334315c3333335c3032375a5c3237315c3336357b5c3033355c3232353269525c3031305e595c303331515c3032314b33315c3330305c30303075245c3332335c3335335c3331375c313737682f5c3032325c3231375c3031317c5c3032355c3336315c3232365c3234355c3232325c3235365c323732745c3236305c3330365c3331325c3330345c30323579475c3232365c3230345c3032315c3331375c3031345c3334305c3337375c303030515c3332365c32313149462e4f5c3234315c3331375e5c32353468525c323235596d5c3032345c3333375c3333355c3235315c3337315b5c3334336d6d5c323734515c3334336d5c3137375c5c7e645c333234755c3031315c3235365c323336455c5c5c3232305d5c333637607c5c3230332a785c3331315c3334335c3033305c3335355c3231375c3232375c303132385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372a5c3234344a5c3230345c3236305c32313446725c303031285c323337745c3337345c3237372a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c323235235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337345c3234355c3335375c3235335c3137375c3332375c3336355c333735775c333736575c3233345c33333549395c3331315c3335325c3337375c3030305c3235375c3335335c3337325c3237315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c3233345c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331332d5c3232355c3233375c323335735c303234515c3330362377755c323137285c323737745c3233355c323430285c333731795e5c3030364f6c765c3330375c3331322d5d5c3237375c3235375c3335335c3337325c33363549393b2e5c3237375c3332375c3336355c3337355f5c3333315c3237345c3031355c3234355c3033353b5c3330335c3032365c3031335c333636685c3332355c323131495c303131445c33343543346c5c3030305c3337355c333337235c3033305c3331315c3335355c323634725c3237305c3337313d2f5c3330313a7c5c323135347e455c323734295c3236355c323233315c3330345c3237345c3235336c2176365c3030374c7a5c3235315c3330305c3030372b5c32363772715c32323656515c3333335b5c3330345c3232315c3333325c323434285c323036255c303031635c333031405c303034402a5c3231372c657e5e4f6d5c3234335c3234363e4f495c3337307b5c32343746255c3236352f6e5c32323032794c5c3231315c3236345c3236325c333434335c303134467c5c3237365c3230305c3030335c3337375c3030307c5c3032335c33303637475c333635305649763f5c3235315c3336305c3236343e5c3235335c3230375c323437417d5c3232345c3232375c3333345c3232323d5c3332375c3334315c3236355c3230305c3232324b455c303230475c3236305c323330435c3337345c3230355c3033354e5c333232325c32343420205c323030315c323134295c303030675c3031335c323637727b555c323234265c3333365c3331365c3031305c3233305c3030305235525c3032375c3033305c3033305c3033305c3334335c3030305c3031375c3331305c3031375c3234305c3235372f5c3337305c313737635c3032344b6855565c3032375c333034795c323130215c333330405c3232305c3230305c3032305c3335345c3334375c3335365c3232335c3231365c323030267823317a5c323434715c323434315c323534715c32353044505c30323555465c3030305c3030335c3234305c3030325c3236343a585c333532285c3234325c3230315c3030355c30323451405c3030355c30323451405c3030355c30323451405c303035555c3332352f5c3334325c3332325c3236345c3333335c3237335c3333315c3331315c3032305c333333445c333633395c303335765c323530245c3337375c3030302a5c3236355e515c333733535c3337305c3234335c3337365c3032312f5c3230305c3233362f5c323733575c3031312c5c3336365c32373761415c323336585c3331345c333032235c3231365c30313745763f404e463226525c3334355c3231335c3232335c33353073625c3235332c355c3031325c3232355c3233375c3333314d5c3337355c3331325c3334375c3334355c3237375c32313035593c415c3334322d53575c323336355c3231365c3334325c3337325c3335324b5c3233317c5c3236345c3033372b5c3237335c3030362a5c323730415c3232355c3336353c635c3033355c3236315c3336325c3334365c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435545c32313163395c3032315c3231305c33313640255c3032335c3335365c3233375c3232375c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3232335c3237375c3336355c3337355c3137375f5c3235375c3336325c3331345c3234345c3334345c3333336f575c3337355c3137375f5c3332355c3331305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3235365c3236375c3236365c3331345c3231325c3236315c3330365c3032315c3331335c3030355c3337315c3032375c3335365c3232335c3236346d5f5c3232375c323235385c3033313d5c3236315c3333335c3033372b635c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3335335c3337303b4e5c3032375e265c33323363585c3230325c3337365c3337355c3031335c3335345c5c6d5c303033692a5c323434272b5c3230355c3335335c3335355c333234635c3334355c3237302e79285c3336375c3337365c3237375c3235375c3335325c3337335c3334315c3335305c3237344568515c3231365c333632697d5c3335365c3333375c3332375c3336357e5c3230335c3334323e5c3232375c3336365c3030315c3234353a42225c323135615841485c3336315c3236376a475c3336325c3231375c32323070475c3030345c3233365c3233305c3335355c3231342f5c3032315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3333303c5c3137375c3234345c3231335c3237375c3031344b3c765c3235315c3031335b3a495c3337335c3237305c333130645c30333363525c3235335c3337335c3236315c3232355c333037527a5c3030355c3335355c3231342f5c3231375c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3335325c3330355c3330375c3232365c3235335c3336335c3337365c3237375c3235375c3335325c3337375c303030555c3330355c3233304f5c3235326672695a32495c3235375c3237325c3333375c3233325c3337365c3237325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3032355c3337375c3030305c3235375c3335335c3337325c3337357e375c3337325c3337365c3237375c3235375c3337303a5c3333365c3032315c3231325c3332313c43625c323637365c3332315c3237345c3031372a5c3330345c3334336f5c3031335c3237336a5c3334307c5c3233345c3235374c5c3232335c3335315c3333335c3033315f6f5c3236375c3236354863535c3032355c3233345028785c3330365c3333305c3334335c3330375c3232363f755c3336325c3235305c3336325c3337365c3335375c3033357b6d5c3033345c3235363e4f5c3233365c333431415c3030335c323037445c3336325c323331485c3337315c3234335e505c3337345c3237342f5c3331335c3331325c333630327b635c3236363e5f745c3336305c3331355c3335325c3335325c3333322d5c3235355c3334325b5c3330365c3235344c6a5c3337335c3032335c33353630315c3030325c3032375c3032315c3336325c3237372f5e5c33333347235c303337275c3235375c3230315c323232695c3330375c3235315c3337325c3332375c3030325c3334325c3335315c3333325c3236365c3032355c3235377b49275c3332365c3333333f5c3237334b7a5c323737535e5c333035565c3032375c3336335c3030355c323632423e555c33373123205c32343656315c3236357e404a5c3336315c3331313d365c3231345c3334335c3033305f5d5c333630365c3234305c3234315c323433215c30323124755c3330365c30323236556d5c333232605c3232355c3337313a5c3232305c323134485c3033305c3033372f5c5c2e225c3336315c3331305c3234305c3030305c3030374b585c3334325c3337315c3334335c333431505c3231355c3233375c3335325c323736555c3337355c3333372b5c3330375e5c333333472b5c3231375c3232335c3236345c3336305c3033355c333634765c30323731295c3230355c3032336b465c3033325c3032345c3033305c3031325c3235325c3234355c3231365c333232575c303333465c303037275c303030755c3334305c3231355c3331315c333532753f58675c3332365c3337365c3031335c333234775c323434485c30323521765c3330315c303336545b435c3232365c3232305c3030365c3330315c3333307a5c3231305c3333305c323230385c3030305c303336703f755c3335305c3032355c3334315c3337375c3030305c303136754877465c333231475c303230485c3231326e5c3231307c5c323333555c303031665c3031335c3237315c303036765c3233345c3030335c3233345c3030315c323136425c3232345c3333355c3033375c3236325c3335315c323237315c5c5c3333315c33303661455c323135505c303034285c323132425c3234315c3030306546405c3335315c3332335c3234305c3330315c3030345c3032305c30313020585c3233316e5c323736545c3337375c3030305c3230325c323035785c3234345c3335315c3233375c3031345c3336343d5c3032315c3033305c3234345c3233325c3233365c3234335c3334365c323631515c323232635c323131795c3033355c3031375c3033335c323335395c3334335c3033305c3337325c3232315c3336355d7e7c5c3337375c3030305c333031425c32373446755c3033375c3231327a265c3232305c3231375c3237325c303335334d5c3031365c333035412c5c3232325c333133212c315c3230335c333031545c323137275c333734323931525c3334355c3234325c3337345c3331375c3232315c3334325c3233344f5c3332355c3336325c3235325c3236365c333336565c3231375c3333365c3336355c3337342e7c5c3235315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337345c3334355c3337375c3030305c3235375c3335335c3337325c3337355c3137375c3233373f5c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3332335c3336305c3335375c3230366e355c3337335c323731215c3236335c323136385c323336355c3031345c3331355c3236375c3230355c3337335c3230336a5c3232305c3233345c3230335c3330373d5c3236315c3333335c3033372e64712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f465c333730495c3234365c3230345c3231365c3337325c33353560407c5c3331305c3234325c3331325c3234375c3333345c33303321217e435c3232355c3330305c3033345c3336315c3231355c3234335c3232315c3231345c3234365c333634205c3235325c333234516f5c3337325c3337365c3237375c3235365c3337365c333536475c3230315c323036655c323330535c333033545c3237372b5c3237355c3335355c3333312b5c3337375c3030305f5c3332355c3336335c3235353e5c3032305c3335335c3032325c323232625c33373324645c30313670594a5c3336305c3031365c3332355c33313463235c303030645c3336365c3335315c3330363e5e5c323633485c3337355c3232357c5f5c3235315c3335366b635c323436465c3032345c303232485c3232315c3230365c3333355c3234306e503c5c3235345c3334335c3031335c333136715c323134605c3334305c3230325c3032375c3236375c3336305c3335355c323134775c3032372c7e5c3331345c3232305c3337345c323134705c323132545c32343622535c3230355c3337355c3333305c3331325c3337345c323433395c3337365c3335305c3030345c3235363e4f5c3234315c3237345c3030335c32343741315c3330315c303230295c3331335c3234365c3335305c3334315c303132545c3033305c3330365c3335365c3235305c3030375c333132545c3030365c333136395e5c3235315c323134475c3335337d4e5c3232375c3233315c3337325c3335335c3334305c3331345c3235352d5c3234355c3337375c3030305c3230315c30333737695c3237375c323630575c3330345b5c3331307c5c333530655c3332305c3234325c333534475c3333325d4a5c3232305c303036507e5c3334375c3232315c3336325c3230307b5c3230335c3230315c3330315c3030342d5c3235305c3337375c3030305c3334305c3233375f5c3032325c303233256e3c3d5c3033315c3030333f255c3333335c3334375c3231345c3031355c3235335c3337335c3233365c323034285c3334345c3334335c3235305c3335315c3337343f5c3234307e5c3033355c3231313e5c333134642b5c3033333a5c3233355c3230315c3332323d5c3233305c3033335c3032305c3032355c3337335c3235335c333233685c3030375c3333357a2e365c3235365c3237355f5c3332345c333531795c3232315c3337365c3234365c3334357d5c3234355c3337375c3030305c3230315c3137375c3330303f39635c3337375c3030305c3230327d7c484c5c3232355c3237305c3336305c333634645c3031345c3337345c3232376f5c32333630365c3235375c3335367a5c3032305c3234335c3232335c3231365c3234335c3234375c3336305c333735735c3337332c5c3337345c3033345c3237375c333730255c3336305c3331355c3336344d575c3335345c3233375c333332775c3032375c3236325d5c3331375c333636275c3333375c3032372a5c3235305c3234305c3032325c323532485c3333335c3033325c3336355c3033375c3334303d5c3230365c3231325c3332365c3233365c3033365c3032345c3234355c3331355c3032335c3332335c3331335c3337307b5c3030335c323236565c3337325c3330355c3030345c3337315c3235356d5d5c3330325c323736255c3337375c3030305c3230325c3231365c3335325c3235355c333437785c3033334e5c5c5c3235325c3030317571215c3031325c3031315c333131312a5c3231365c3230345c3334335c3230375c3331374e5c3333365c3233315c3033376d575c3330315c3333375c333630515c3231355c3333375c3336305c3233315c333730405c3232355c3330325c3031335c30333140755c303331604c5c323433235c3033303c5c3033345c3031345c3233363f5c3235305c3231345b5c3337355c333133395c3237305c3236324e3945545c3237325c3336325c3337375c3030305c333531485c3337305c333736385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337315c3333335c3337375c3030305f5c3332375c3336355c3337325c3337375c3030303f5c3137375f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3235335c3334315c3033305c3032357c4f5c3234355c3032315c3033304c5d455c3232335c3033327d5c3332335c3237313e555c333731395e5c3030364f6c765c3330375c3331335c3232355c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232365c3335365c32303522695c3333325c3330355c3232355c333130455c3231375c3331315c32333636625c3235315c33363770535c3334355c303337285c3331325c333430727b635c3236363e5d295c3237377d3b5c3337375c3030305f5c3332375c3336355c3333375c3235335c303133355c30313445394b645c3332375c3334365c3237375c3235375c3335335f795c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337312c5c3335315c3232305c3235325c3331305d6d5c3234335c323034605c3031375c323235765c3232345c333731235c333731575c3334345c5c5c3235375c3033355c3137375c3333315c3030335c3236365c3032365c323634505c3230305c3235325c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336323e5c3333323f2f5c303232476e5c3236305c3033355c3331303f765c3230345c3032345c30303444365c3235375c3335365c3330312b5c3230315c3230327b6d5c3033345c3231347c5c32333751735c3337325c3234365c3330375c323730783b575c323637745531225c323633335c3031305c33343555245c3236302c5c3032345c3030355c3337315c3030315c3330315c3031315c3232335c3332305c3030305c3237346029585c3337365c3231335c3336305c3233365c3236355c3030355c3330325c3234365c3337305c32343256625239634f5c3237345c32373154505c303030455c333532235c3331313c5c3031375c3232375c3231365c3032355c3232363f5c3231357c335c323532345c3031345c323535225c3330365c3231345c3032305c303237485c3332305c323232305c3033315c333131525c303234645c3030325c303037523b5c3033345c3235365c3332305c3331315c3335355c3033365c3031325c333631485c3236345c303032245c323035365c323534615c3031325c323032432e5c3333346d3c2a5c3334306e5c3031355c3330305c3330375c3333345c3335305c3235365c3237375c323733495c3335315c3235305c3235357d5c3231375c3234335c3335305c3235365f5c3330335c323336235b5c323130225c323130615c3332305c3232305c3232315c3033355c323435415c3030305c3230355c30303154205c3334335c333435735c3233365c3030315c333031235c303030325c3330375c323737637a5c3232375c3332365c333432455c3334305c3231365c303330615c3236305c3033335c3033345c3230315c3232305c3031315c3330315c3334335c32343750415c3330315c3030345c303133245c323633455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c303031455c303234505c3030335d5c333034685c3331345c3330345c303035515c3232324f415f5c3231365c3237375c3032315c323734455c3337375c3030305c3031315c3231375c3330342f5c3032315c3335335c3334345c3232335c3337355c3234315c3235304d705c3033375c3030345c32323556705541285c3031315d5c3234305c3031345c323334635c3033355c3236315c3336325c3337365c3234375c333734795c333631315c3336305c3230375c3330315c3237375c3033306a5c323130485c3232362d3a585c333432605c3031315c333333235c3231372d5c303137435c3332315c3233305c3033375c3336305c3235375c3331305c3330345c323131505c3232365c3032315c3231305c33313640255c3032335c3335365c3233375c3232375c3334355f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337305c3337305c3337316b5c3033305c5c5c3337345c3232335c3231365c3236315c3032375c3232355c3031343a7d5c3033345c3233375c333137455c33373131235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f265c3337375c3030305c3332375c3336355c3337357e5c3237375c3232355c3137375f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3335335c3137375c303134345c3236355c3236355c3336305c3332325c5c2d5c3237325c3030375c3233325c3334305c303236605c323737705c3030365c323135765c3235375c3331315c3331325c3337345c3237357d5c323037235c3033314f255c323136255c3231345c333435635c3032315c3233345c3230304a275c3333353f285c3333325c3237372f2b5c333037275c3236363b635c3334355c3336375f5c30313569474c5c3332305c333534615c33373334685c333530225c3333375c32363539527c5c323432425c3337365c3335375c3232315c3330375e5c333333472b5c3231375c3232335c3332325c333031465c333633725c3337365c3237375c3235375c3335335c3332375c3336344e5c3031305c3234315c333535315c3336335c3235345c3336365c3231345c3137375c3032365c3332375c3335315c3137375c3335337e5c3235375c3330325c323332755c3237355c3330355c3332367c5c3237305c333430725c3234354a5c3031305c323630635c303036215c3233355c3234345c3234305c303035465c3332355c3331316c745c3033345c3235365c3333345c3234375c3332305c3337365c3030315c3236342b225c3236315c323231625c32323148236c5e5b285c3336325c3230365c303330655c3032347c5c3234305c3031345c3232335c3236375c30303475403e4f5c3032345c333630255c323331795c333431516b5c3032365c333235685c3330315c3231362e5c3031325c3033345c303334796d5c323634745c3330315c3033355c3237305c3334375c3334355c3333335c3237313e5c3231335c3337307b5c323436306b385c3234355c3236375c5c66255c3333355c3336374a5c32313430255c303130415c333136415c3335315c3236375c303330275c3030336e5c3334345c3336367d4f5c3333335c3236365c3332345c3336355c3235355c3033325c3032345c3230365c3331345c3030355652426e535c3033365c3331345c3033372d475c3033372a5c3334375c3230303b7b715c3231345c3031335c3336355c3033355c32373279565c333631275c3232365c3232316d503c5c3237305c3337365c3335325c3336315c33323070385c3033374152555c3232325c30323451455c303030794f5c333535315c333631657e5c3031375c333734295c3332345c323635485c3233315c3230365c323533795c3337365c3230335c3234375c3230345c3335325c3236335c3237325c3233343f435c3330325c3030305c3331355c3332335c303337285c3030375c3033315c3331357e535c3236365e675c3233315c3330315c3336335c3033315c3236325c3335365c30323724315c3333335c3330303b795c3030375c3033345c3233376e5c3333305c3337317d5c3336375c3336365c3331335c3337305c3237343e267c545c3232365c3330325c333036476d5c303233405c3331355c3232342e5c32373122495c3236323c5c3332375c3030336f42405c5c5c3334375c323434605c3334345c3137375c3031375c3331375c3336315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e7b5c3032355b5c3333325c3332345c3236325c3333315c3033375c3331375c333334515c3233325c313737685c3334335c3234355c3031303f725c3233375c3237325c3237345c333337575c3336335c3137375c323032415c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3336315f5c3337325c3337365c3237375c3235375c3332375c3334343f5c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3234355c3337375c3030305c3235375c3335335c3337325c3337354f5c3335335c3337325c3337365c3237375c3334305c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3137375c3335335c3337325c3337365c323737535c3337325c3337365c3237375c3235375c33373024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331325f5c3337325c3337365c3237375c3235375c3332345c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232375c3337365c3237375c3235375c3335335c3336353f5c3235375c3335335c3337325c3337375c3030305c323032475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336365c3331375c3030335c3234305c3137375c3031335c3335315c3336322c5c3032315c3031345c303234525c3331305c323737775c3031355c3033305c3330325c3337365c3335375c3232315c3336325c3336327b6d5c3033345c3231347c5c323336275c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3333307e5c303333475c3337375c3030305c3032345c3233355c3235365c333333685c3332345c33303739525c3331325c3237345c3231375c323336335c3230355c3337355c3333372b5c3330375e5c33333347235c303337275c3234335c3230325c3232375c3237365c3332375c3232375c3337315c3137375f5c3332365c3237375c323432703c5c3335355c323330545c323137783f5c3330315c3330345c3335322d5c3234335c3336325c3331305c3232323b755c3230335c333436415c3337335c323634205c32343022215c3236355c313737765c3031315c5c5c3031345c3032335c333333685c333434635c3334345c3336365c3231375c3030315c3331325c3237315c333633365c3234365c3031325c3236305c3333356f5c3032315c3333325c3330345c3331305c3030365c333430365c3336305c3031315c3033365c3330335c3231365c333431765c3330355c3334325c3236305c3330305c3234305c3030375b645c3231306f5c3231375c333536475c3331325c3137375c3235325c33373157315c3336325c3237372f275c3236365c3332315c3331305c3330375c3331315c3335337e5c3030375c3237335c3137375c3333346d655c323132473b5c3233305c303130705c303334345c3233345c3230355c333032607d5c3330335c32333476535c3331365c303030317b6b5b5c3233375c3236373d5c3031375c3234365c3237345c3030325c3331332c5c3231345c3335305c3232315c3230355c3333305c3337345c3330345c323035545c3337345c3337305c3333345c303031515c3231355c3333337d5c323732635c3233355c323733625c3335335c3235375c3033315c3332325c303230505c3232305c3333335c3332307c5c3234335c3236365c3334315c3233365c3330375c3236367b7e235c3235305c3334327c5c3031332a5c3230305c3235345d505c3237365c3334305c3033325c3031305c3336305c3033345c3233315c303037415c3236335c323030765c3233345c3336345c3334305c3033364e5c333334455c333233785c3232345c323432585c323236615c3033306c6164635c3230375c303037725c3236365c3032375c323137452c4e575c303333415c3331325c333433725c323631335c3230315c3332375c3236355c3235375c3236312e5c3330355c333731672a5c303235422f5c323236545c3030315c323634305c333731405c333130285c3237315c3334305c303230405c33343030515c3031375c3032313f5c3231355c3332365c3031335c3230345c3231356e215c323130445c3331345c3330355c323236303c5c323731335c3331332e5c3032375c3030335c323533645c323032315c3334355c3137375c3332333f5c3232325c3031375c3231305c3233325c3232325c3330305c3236332a5c3330345c3236365c3235315c3033365c3336305c333431545c333536625c3235375c3233375c3232345c303035525c30313632795c333332465c3332335c3231355c3230335c3233305c33373453565c3336315c3032345c3333376c465c3230305c3030355c323036335c323035745c3033335c3231306c5c33353556515c3236305c30323030464f5c3033305c3333325c3237305c3030302a5c3230345c3033375c3232306c5c3231375c3234335c3336345c3331375c3033355c3337315c3336305c3237345c3232315c3330355c33343665446d5c3232315c323631555c3232375c323232546d5c3030354e425c3030335c3230335c3330365c3330325c3030365c3332325c3235335c3236335c3234345c3236305c3336315c323432413c455c3031344421605c3334325c3031305c3237366f2947635c3334355c3231364a5c3330345c3233315c3334305c3031345c3033365c333334795f265c3335315c333336295c3232365c3030345c3330315c3231335c3334365c3030305c333537455c3033335c303234484e5c3335345c3234365c303235785c333435475c3033375c3333355c3033302a5576745c3236365c323336385b695c3032345c323533435c3033365c3330362859225c303331285c3030305c3030305c3235365c3032306722345c3033303b7a5c3336365c3331305c3336325c3232355c3330325c3330375c333236365c323736325c3231366f355c3236366e5d5c3235332a5c3232325c3337375c303030295c3030375c3030335c3031305c333333405c3337365c3033315c3033335c333436235c3033305c3334376e5c30333047645c3337305c3235315c303237765c3335305c3332335c333435505c3330375c3032325c3032315c3232335c3330365c3334355c303331515c323032305c3337375c3030307b5c3030335c33343439235c3031375c3236335c3334364b3f5c303336235c3235335c3236332b4b5c3233345c3331325c3031305c303035465c333030715c33363265465c3335375c3237325c3333345c3337355c3031315c333332375c3031305c3336355c3031375c3231357c5c3332355c3233345c3331316f5c303332645c3231315c3033305c3031342e4e795c3031335c3336325c3231355c3237375c3336325c3332305c3334305c3335355c30333727385c3333325c333736597e5c333431635c3331323f6e6f5c3230367a465c3233337b5c3234365c3337305c333237495c3236355c3236375c3332335c3234355c3237345c3232352c5c3235375c3234325c3236365c3231375c3033335c333434295c3232357c6c5c3033303f5c3237336462405c3337335c3231335c3333343e5c3331375c3232325c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337355c3033355c333733555c3337305c333535757b6d27465c3032315c3231305c3334365c3336335c3231355c3334345c333736505c3337335c3237346d505c303237605c333030245c3331305c303136315c323634285c3331305c303037213e715c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336335c3333305c3235337b69585c333736785c3334325c323130515c3230366b56347c5c3235376e5c333636575c3337375c3030305c3230335c3334365c3032315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f255c3337375c3030305c3235375c3335335c3337325c3337357e575c3337325c3337365c3237375c3235375c3337303d5c3336375c3330323b402e5c3336355c303131525c3032345c3033335c3030342a5c333333535c3335365c3334355c3332375c3230353e595c3331325c3334317a5c3336315c333230745c333036575c3332375c3236345c3031352e395c3235375c3030325c3337315c3032315c3330345c3330355c303333215c3030365c3333372c5c3231305c3332375c3230353b5c303036575c3334345c303331275c3033355c303030245c3030315c3336325c3337315c3335375c3330323d5c303230475c3234325c3331337261485c3337345c3333315c3236325c303330205c333731425c3335345c3330325c323536575c3232352548275c3236365c3332315c3333345c3031355c3237365c3336355c3334305c3233375c3031365c3330305c3333365144565c323131366d315c3235335c3031345c303031214c5c3234365c3032332830783d3e535c3231345c3032304c5f455c3230365c323133545c3234325c31373745705c3330352743295c3234325c3234355c333235375c3336375c3236365c3332375c3334307a2f5c32303134285c3236375c3235342d5c30333471292e5c3330355c3232315c3031323a5c333536456240315c3230315c323030475c3331355c3232325c3234335c3230315c3336375c303036447e5c3337335c3334315c3237353c59415c3230316f5c3032325c3031345c3232365c33333623285c333033725c3234315c3330305c3030355c3032375c323537735c3335325c3234335c3230315c333637535c3230345c3336302f5c3230375c3334305c3232325c303133795c3032362d5c323431765c3033355c3231325c3234375c3334345c3030315c3331325c3031355c3230342e575c323032795c3335315c3336325c3232325c30313641317a5c3232355c32373279565c333631275c3232365c3232316d503c5c3237305c3337365c3335325c3336315c33323070385c303337415d685c333732624a5c3337315c3230375c3337365c3031325c3030335c333432775c3332323e5c3032305869515c323731535c3235325c333532515c3234345c32303172495c323136305c5c5c3336315c323032315c32373026735c3332335c3235375c3237305c3337327a5c3237365c3030365c3337375c3030305c3230325c3231305c3337305c3233305c3333365c3337305c3337335c3330335a5c3033325c3232365c3336325c3336345c3337335c3030365c323731665c3031335c3332315c3334365c3232335c3033305c3033345c3033345c32313444327b7e785c3334355c3330355c3331335c3232365c3232335c3336333e535c323132315c303337575c3331325c3235325c333333795a3f7b5c3332375c3336305c3237315c3336323c712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336335c3232375c3337365c3237375c3235375c3335335c3336355c3337367a5c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232377b5c3330307a5c3137375c3233375c3334325c3237353f644a5c3237365c5c5c3235325c333534517e5c333436365c3336305c323737272b5c3330305c3334375c3333335c3235305c333036575c303036385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f735c3336305c3233334c565c3332345c3335365c3335365c323034285c3031342b5c30323261535c3335365c323236745c3334317e4e465c3032335c3235375c3236376c657a305c3335335c3233365c323534575c3336355c3337355c3137375e5c3237365c33353645435c333533395c3233355c3031325c3137375c3333364f5c3334345c3236355c3137375c3230325c3337365c3237325c3337325c3232355c3234355c3233325c333130775c303133785c3334305c3030305c3235315c333731535c30303530223b57315c3231345c3235375c3331335c3231345c3336355c3033334742305c3237365c3237375c3336305c3337365c3330323f26385c3232375c3331335c3336325c3332314b2b475c3033305c333332405c3232305c3032315c323030535c323030765c323137435c3336325c33363525715c3032375c323233695c3032365c3234355c333435665c3231325c3331355c3032305c3230355c3331315c3031305c3230345c3032345c30303234242f5c3331305c3234345c3235365c3032375c3232335c333333685c3336345c3330325c3337335c3332375c323032345c333035285c3335355c3033355c323732263c5c33323259415c303034605c303036205c3030305c3230335c3235365c3031367a63685c3030342e365c3330375c3336346f5c3237315c3337352d5c3334347b5c3231375c3230315c3335345c323435505c3033315c3236365c3235325c3232305c333134255c3230315c303030463b5c3332345c3233347c5c3237305c3033315c3030305c30303238235c32343725765c3330355c3333325c3332365c3030375c3230345c3335355c3032325c30313352525c3031305c323235435c3237365c5c2e5c3332365c3030345c3335355c3331305c303033685c3335365c3031367d5c3031325c3230315c3230355c3330365c3330345c3333375c323532255c3335365c3032345145315c3030355c30323451405c3030355c30323451405c3030355c30323451405c3030357c5c3233355c3337375c3030305c3030355c3032305c333631375c3333303e5c3033355c333730734457647d4351375c30313453245c323632445c3233302a465c3031375c3033335c323435427d315c3337305c3231375c3235346b5c3336335c3331335c3337365c3031325c3031315c333432575c3332353e2d5c3335317a483f5c3335305c333732565c3233345c3233345c323530625c333133245c3235375c3237315c3237302b5c3231345c303235585c333632475c32343727235c3334355c3334335c3330355c3331375c3232365c3232335c3336335c3332305c3337315c3031362b5c3330347b5c3031345c3234365c3234325b5c3331325c3332315c3337335c3333365c3237375c323032675c333133715c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3331365c3333375c3337325c3337365c3237375c3235375c3332375c3337315c3337335c3337325c3337365c3237375c3235375c33373024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5e5c3333335c333431465c3232365c303337585c3237305c3237325c3032365c3335315c3236365c3030345c323135495c3031335c3336375c3033315c323335305c3032375c3334345c3334346d535c3331376c755c3033305c3331325c333631315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d4f5c333431565c3232342d5c323634496e5c3332365c3333355c3032355c3234355c3237305525535c3232355c303132635c3334314e5c333136575c3235373d5c3236365c3336355c3033305c33313276615c30323735555c3337355c3137375f5c3332375c3331375c33353378575c3031375c3336355c3231345c3333325c3232335c3335315c3033335c3331315c3337345c3232365c3233375c3231355c3237375c3235355c3337335c3231335d2a3d46295c33343136515c3231305c3334345c3231305c3235335c3234325c3234365c3031322f5c3232365c3233315c3031325c3031325c3031345c3235365c3032375c3232327a6d5c3033365c3233305f5c3233375c3236355c303135295c3336346d4e5c3335365c333136585c333034535c3333334c5c3332304b5c3236323236325c3232305c32343557285c3031365c3333375c3232375c32323240235c3033355c3236315c3336325c333735255c3334317d3e2b5c3233335c3336305c3033325c3030345c323637525c3234345c3033355c3231315c3230335c3033305c3336325c3232375c3230355c3331325c3031345c3235305c333332335c3232323e5c3335305c3030345c3235363e4f305c3337305c3337355c3334315c3237305c3236343f5c3033357d5c3235325c3031305c333235225c3237365c3230312669225c3231345c323134495c3330325c3236325c3334305c3234305c3337365c3334305c3031355c3332335c303034745c5c6d4e5c3335346c2f5c303235355c3332305c3337335c323536395c333031735c3334315c3235315c3334325c3234325c3236355c3231335c3236335c3336347d5c3337366b5c3336313c5c333132385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336316f5c3337355c3137375f5c3332375c3335335c3337305c3330375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237365c3231335c3336305c32343350454b5c323135385c3330345c3231325c333533224c5c3233305f5c3237335c333633465c303331575c3336377c5c3235365c3032354e7d5c323733632b5c333437515c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731755c323734257b5c3033365c3231335c3334325c3031332b5c3234365c32313424692a5c32313136285c333731415c333332303e4e575c323030735c333333685c3335315c3231375c3232375c3234325c3230354e4a5c3231315c3337375c3030305f5c3332375c3336355c3335335c33353764585c3335375c3335345c3337345c3330365c323235765c3335345c323537675c3335305c3336345c313737765c3337375c3030302f5c3237375c333334225c3230305c3030305c3033352d635c3231335c3334375c3231375c32303542365c3137375c3235325c333731575c3336377c5c3235375c3033357b6d5c3033345c3235363e4d2d5c3030325c3334315c3335345c3234375c333633635c323034405c32343070235c3337315c3031346d5c3334355c3235305d5c323731415c3232303d7a5c3231355c3234305c3030325c3031375c3333355c3331355c3231325c3032305c3032343a5a5c3330375c3032375c3331375c3033375c3031325c3230346c5c3337375c303030555c3336325c3235375c3335365c3337315e3a5c3336365c333332395c5c7c5c3232325c3333315c3330365c3236315c3236375c3233305c3236365c3335335c3030305c3331325c3231375c3333355c333036725c323331585c3230365c3332355c3033365825785c333031275c3234365c3333365c3333305c3330325c3337355c3033355c3335355c3235315c3337352b5c3334347d5c3031315c3334307d5c5c265c3332375c3231335c33313327696578705c3234357e45485c333330615c3030305c333534795c3334305c333435385c33333241585c3337365c3230355c3336305c3236335c3031335c323133555c323334475c3031315e544a5c3231325c3032345c3230305c3032355c3030305c3030335c30313232305c3237345c3337335c3235305c3033305f5c3237305c32333725785c30313352325c3236325c323532325c3330353070245c3031335c3033305c3030315c32363738242e5c3032375c3030335c3230315c3331305c3337365c3335325c3336355c3330305c3030362f5c3234333c5c303231785c3334375c3331305c333332565c3033315c3033345c3230325c3330304240705c333232725c3032375c3031315c3230304e5c3330324e3b295c3334375c30303079545c3231313d5c3033325c323737275c313737696f5c3032325c3231375c3032377c785c3336315c3233365c3234345c3234315c3330325c3235355c3337315c32363456316d60215c3031315c3031305c3030305c30323078223c5c3232335c3233375c3331335c3337305c313737525c3337344d5c3235365c3235375c3230367c295c3235325c333533374a5c3235325c3233327d5c3232345c323637725c32353062545c303034425c333034675c3033315c3330375c3030375c323334575c333433655c3332345c333537797b7177305c3033367c5c3332325c3032375c3232355c3332315c3030305c3337315c3233305c3231345c3230315c3230345c303331535c3333345c3336365c3330376c7c5c3237365e3e5a46275c3334357c755c3231305c3236352a5c3033307e5c3335355c3331335c3335365c3332317e6c5c323032385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336315c3235375c3337355c3137375f5c3332375c3335335c3337315c3032375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237365c3330335c3336305c3333374e5c333733275c3230355c3235355c3233345a5c3330365c323135245c3333335c3333305c3235305c3331315c303331685c3330365c3032375c3336377c5c3235365c303234735c333333685c333434635c3334345c3336315c333730605c3030315c3330365c3331305c32363631215c313737765c323331205c3337345c3234336a5c3337345c3237345c3235315c3330305c3331315c3336365c3335355c3231375c3232375c333337745c323535396c345c333733685c3232325c333332345c3336325c323034284a5c3330375c3230325c323734435c3232303f74323e5e4e385c333332395c5c7c5c3233365c3233365c3030355e4e5f5c3332375c3336355c3337357a5c3337365c3232375c3330305c3333307e7c5d5c5c47485c3330352f5c3237355c3337375c3030305c33303067575c3334315c3030375c3231365c33333655705c3231335c303130422468525c3030335c3232355c3333335c3032313f215c3333305c3031365c3032345c3030315c3333354e715c3331325c3335355c3331327b5c3237375c3230335c3236355c303031625c303232445c323132365c323131585c30323255425c323630755c32313554635c3334345230725c3031363041505c3030365c3332325c3030304f5c323336745c3231315c3337345c3234345c303030425c3032323d5c3233334c61765c3231305c3331365c3330305c3030305d5c333130325c3234333d7a5c333434635c3230335c3336377b5c3331355c3033335c3330355c303231695c333237435c3335345c3335335c30333040585c3237305c32303149255c30303166625c323433605c303033215c3032373d383d5c3230305f2b5c3333305c3237315c333733435c3332315c32333758693e26586c403b245c323135545c3033305c333130605c32353250605c3030305c323730503a5c30303739385c303337295c3337335c3234303a5c3330376c785c323631705c3334355c333431545c3333325c323731205c333130464e46405c3331325c3231345c3032315c3230375c3337335c3333305c3337335c323437385c3330335c3335345c3337315c323734785c333436315c3033345c3230345c3333335c3232325c3235325c32303252505c3232335c3232315c333136765c3233355c3237345c3337355c3332375c3334335c3231365c323033385c3330335c3337316f5c3232335c3330375c3236315c333130255c3232315c3235355c3337305c30313226635c30333742395c3331365c3333375c3232345c3031375c3334317e385c3330365c303036765c3334315c3337345c32363771585c33373234785c323631705c3334355c333431545c3333325c323731205c333130464e46405c3331325c3231345c3032315c3230375c3337335c3333305c3337335c323437385c3330335c3335345c3030375c3231335c3032375c3031365e5c3032354d5c3235335c3232325c3031345c323034645c333434645c3031345c3235305c3330315c3033305c3137375c3237355c3231375c323732735c3231343e5c3331375c3233345c3234345c3336315c333534725c303131646b7e5c3030325c3231315c3233305c3330375c3332305c323136735c3236375c3334355c3030335c3337305f5c323136315c3230315c3233355c3237305c3137372d5c3330335c3330372b705c3335364d5c3237325c3231345c323031292a765c3235315c3030345c3233345c3335353b405c3335345c333734715c3231345c3031345c3335355c3330335c333731655c3330325c3330375c33323250785c3231304f32445c3032323d5c3331355c323634705c3331375c3332345c3232305c3031305c3330365c3331345c3334347c5c333735715c3336375c3031374c3e5c3331375c3231355c3337375c3030305c3334305c3234315c3336366b7d5c3033375c323031755c3235305c3332305c3230323e5c33323569345c3231325c323136765c3236375c333536582025315c3231345c3335375c3030375c3234315c3033303c654e5c3333376e5c3336305c3235375c3231315c3233365c333631775c3236335c3234305c323134645c323734515c3330345c333132555c3236305d5c3231325c3334315738205c3030335c33363770425c3231375c3232345c323430295c3330375c3337365c3333303e5c3033315c3233335c3330345c3337375c3030305c3030325c3235366e625c3236365c3337355c3335365c3231357b5c3032355c3335315c32323638465c3335355c3230302c5c3031345c3234335c303130305c303030705b385c3334313a2e5c3332325c3236315c3336335c3334325c3232355c3335305c3331315f5c3337325c3333345c3337315c323536235c3330335c3237344e555e2b5c3234325c3237375c3337365c3030325c3332335c3337355c3031375c3331375c3033305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3334365c3335375c3337355c3137375f5c3332375c3335335c3337345c3334355c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304c695c3336377e5c3335375c3331325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314b5c3337375c3030305f5c3332375c3336355c3337325c3233375c3332375c3336355c3337355c3137375c3330315c3336365c3137375c3030326a63575c333230615c313737225c3032355c3233365c3333355c3334335c3230364f2d795c5c7940635c3336377c5c3230325c3032375c3235375c3337333d463e4d5c3337305c3234305c3030305c3030374b585c3334325c3337315c3334335c333431505c3231355c3233375c3335325c323736555c3337355c3333372b5c3330375e5c333333472b5c3231375c3232335c3330347c2b5c323537495c3334315c323135404f5c3033344a616641346a5c3230305c3336305c3031325c3232305c3235335c333632745c3334307c5c3333355c3236315c3333335c3033372f5c32363269375c3236365c3233325c3235355c3235325c5c5c333331475c3031315c3231377c605c3337316b5c3331345c3137375c3335325c323736503c5c3237365c3233372f5f5c33363647235c303337275c3237375c3230375c3235365c3235325c333035265c3336353f5c323430386b3a5c3234375c323331616346725c3337355c3335345c3032355c3233325c3335365c3232375c3333325d5c3337345c3337333f265c3231352b5c303232213b5c3230355c3236325c3330345c3237372a5c3334315c3032305c3334363c5c323534602a5c3231355c3230305c3232355c333635275c3234365c333336715c3231342f635c3234325c3337305c3231355c3235355c3032315e415c303232485c323037715c3231375c303337265c3337345c3236335c3232325c32343150715c3232305c3230335c3232323a2f4c295c3231375c3230365c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337315c3033355c3030325c323634615e3b755c3230375c3031345c3231335c333632215c3030355c3030315c3336325c3236325c3235335c3337335c3237345c3232355c3330305c3334345c3337375c3030305c323632395c3033305c3337313b5c3031375c323633675c32373678535c3330365c3335335c303034615c303236455c3231355c3032305c3030365c323136735c3032365c3332305c323430655c303237615c333330315c3231355c3235365c3330345c3336315c3231355c3237335c323630365c3232315c3033375c323432695c3033363f5c3031376a665c3230365c3033305c3233355c3332305c3235325c3032305c333530402c395c333130525c323734605c3234325c3030325c3030315c303034605c3235305c3330365c3332355c3032315c3337345c323531615c3235345c5c5b5c3230345c3232315c30323044725c3237335c323330464b5c3234335c323230315c323637295c3233347c5c3334375c3334365c3334335c3030345c3030335c3332347c5c3237355c3031355c3232375c3231335c3033325c3031305c3234355c333034485c3033335c3031325c32303630365c3231355c333337785c32373261785c33343426707b60635c3031335c3334355c3237335c323233635c3335325c3331335c3031375c3033335c3235325c3331315c30313664565c3032305c323036505c323230455c323232225e485c303037605c33303656304f5c303030735c3333333f5c3237325c3333365c3230335c3330365c3236315c323733315c3032315c3033315c3032355c3230325c3331305c3031365c3337375c3030305c323230295c3033375c3330325c333035403f755c33313727235c3237365c3332305c3033375c3331335c333731565c3332375c3330374b5c3030345c3232365c3337375c3030305c3237345c3231305c323534445c323431585c3234335c333434443b295c3336325c333037515c3033325c3336315c3230303e6e5c3333315c303336565c3237355c3236375c3231367e5c3332345c3331325c3235325c3337345c3236335c3337315c3330375c30303368315c3030335c3230325c3032305c3236305c3033347c5c3234372c7b735c3336325c3030325c333336535c3032315c3336355c3033355c3237375c3231305c323236795c3332322d5c3231305c3033315c3236365c3231365c3033315c3331375c333134715c3232315c3231355c3230305c3334347c5c333735715c3336375c3031375c3234335c3335345c3332305c3236355c3237317b5c323235465c3336325c3336365c3031355c3237317d5c3333335c3230315c30313440205c3030305c33313232393c5c3336315c323032315c3231345c3334375c303336335c3334316f5c3032332d5c3335345c3030315c3237365c3335315c3033313224685c3330302b5c3030305c3331365c3334355c303030455c333530425c3230335c32323230547d5c3332325c3234305c3330375c3335325c3233365c303333525c333630795c323036285c32373652535c333134545c3031305c3331335c323035415c3236345c3031355c3230335c3337335c3237303e5c3335325c3030365c3032375c33353620336e5c323132285c323436205c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030335c3334365c3233375c3333335c3335375c3330345c333037475c3337302d6f5c323436472b235c3335325c3333325c323234305c3237322a5c3232335c323732345c3331345c3230375c3333335c3033335c3232363e5c3237365c3237365c3333315c3033375c3233345c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e5c3237375c3337375c3030305c3230325c3231315c3337305c3234345c333336785c3331335c3330325c3333365c3033374d5c3330312c6c5c3333365c3335355c333330215c3331365c3335315c5c285c3033355c30313646225c3334345c3336365c3331375c3334355c3336325c303034712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3233355c3330355c3331375c3233325c3236335d5c3237375c3235375c3335335c3337325c3237375c3336335c3337375c3030305c303236627e5c3236315c3233325c3332344b68255c3033375c3332355c3337362d5c3337375c3030305b5c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3033355c3337375c3030305c3235375c3335335c3337325c3337357e3f5c3337325c3337365c3237375c3235375c333730375c3237343f5c3234355c3234355c3337365c323633656d5c3334355c3337316b2c5c3331315c3033335c3233305c32323325412a5c3031305c5c2f2b5c3230315c3331315c3335355c3231365c3333305c3337317d5c3334365c3033305c3032345c303035655c323636485c3230365c3335305c333730485c3337314f5c3336355f2a5c3334363e575c3334355c3334345c3336365c333332395c3033305c3337313c5c3231335c3334315c3233365c323330275c33363134525c3235355c3237325c3334325c3333345c303037625c3032335c32303439455c3330325c3337345c3233345c323134775c3335355c3231365c3234335c3033315f635c3332335c3335355c3230317d5c3335335c3030325b5c3230315c3231375c3237305c323730295c3336325c3330375c3336325c32353650657e5c5c5c3032335c3332375c3334355c3030335c323134617d5c3237345c3032345c313737765c3334355c3333345c3337355c3236335c3230315c3336305c3335325c3233365c3031325c323436215c323535652b7c5c3232325c3337375c303030365c333137465c3337307d655c303234225c3332375c3031305c3236305c3237315c3032317e5c333530464a71215c303030215c3333315c333333693e5c3233304c5c33363046625c333732475c3334315c3337365c323336235c3236375c3230315c3234315c3231355c3032315c3030325c3234325c3232345c3032305c3230325c3030325c3231315c3237305c3330315c3031315c3330373d5c3331375c303337275c3030375c323032625c3336312f5c303034584d5c3031312645545c3330365c3337345c323734485c3030325c3232335c3237345c3032335c3230315c32363463385c3030305c3231365c3031305c333036392b5c3236362f5c3234347c5c30333164625c3333372f5c3333315c3232365c3032305c3031345c323132595c3031305c30313249615c3332306d5c3030345c3033375c3232375c3334365c3335315c3230335c3230315c3231375c3232342c7e5c3231325c3336323f46674f5c303334695c3031346b5c3033346a5c3032315c3032345c30303555515c3230305c3030305c3335305c3030305c323437514551215e375c333733557c5d5c3033375c3031313e5c3032355e5c3333345a5c333334495c3030365c3237315c3235315c3137375c323431695c333436215c333633235c3236375c3333365c32323338385c3333325c323731395c3336355c3330374e5c3234335c3333305c3331315c3330305c3235375c3331335c3337375c3030305c3333325c3333375c3334325c3336305c3337305c3235375c3336315a5c3334345c333331492b685c323332366c2c5c3331315c30333548615c333436485c3234336f47615c3332375c3337335c3235305c3237315c3330363e5e4c4d5f654f5c3331355c323337295c3330345c3237315c3234375c3336366e5c3030365c5c5c3231365c3332335c3233365c3232315c3337355f5c3331317e363c476f5c3335375c303332425c3237335c5c5c3232315c3237355c32323572413b785c3030376f2a715c3331315c3336365c3335355c3231375c3232355c3236315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3233345c3237375c3336355c3337355c3137375f5c3235375c3336335c3331375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f795c3334302f5c3230365c3332365c333736205c3332335c3333365c3336365c3335345c3331316c5c3231345c333333535c3335345c333733545c323536365c3230325c303036535c333436535c323134675c3236365c3333345c3137375c3237335c3235353a725c3235332e585c3337375c3030305f5c3332375c3336355c3334375c3335315c3334355c3337317e23335c3235355c333534305c3331325c3336325c3236355c3337345c3235345c3237335c3337375c3030305f5c33363078385c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3234343c335c33373335786b535c303131275c3333325c3236355c303134645c303032612a5c3030365c3333355c333333325c3237375c3237315c3331305c3030375c3030305c3336335c3330375c333130467a5c3337317e5c3235375c3334315c3237375c3333305f5c3330305c3233325c3233325c3330365c3337375c3030305c3333323a5c3332305c3330315c333033345c303232465c3030332e5c3337355c3233315f5c3336347c5c323030405c3030375c3232315c3231375c3232335c3235375c3333365c3336325c3337325c3237365c323437545c333732575c3330315c3333315c323537655c3337375c3030305c3230315c3033375c303134475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337365c3230375c3330315c3337375c3030305c3030345c3336335c333730705c3231305c323534755c3031357e29365c3030304477365c333434295c3330305c3331365c3031375c3232303d5c3030305c3335315c3333307030305c3334345c3337375c3030305c323032795c333734365c3231345c333435352f5c3032305c3234315c3333335c3236345c3032355c3237305c3236375c3033305c3335303f5c3334375c3230375c3236305c3337375c30303020615c3337354a5c3235305c3137375c3235315c3333315c323537685c3337375c3030305c3334305f5c3332375c3336355c3336333f3b5c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337315c31373744535c3337365c3031315c3334375c3336305c333332335c3232345c3332345c323734425c3230376e5c333230565c3334325c333334635c3234305c3337375c3030305c3233365c3033365c3330335c3337345c3230315c3231375c3231365c323737685c3137375c3230355c3237326f5c3330315c3335375c3231325c3337325c3234375c323037345c3230365c3237307d365c333336385c3033365c3033315c323536765c3236345c333330785c323433245c3032325c3236315c323530237023235c3234305c3030335c3233363e5c5c6a5c3334315c33343749734b5c3337325c3337365c3237375c3235373f2f315c333130315c3237315d5c3032355f5c3032336e565c3335355c3234335c3237365c3237325c3337375c3030305c3232315c333436715c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f2d5c3337375c3030305c3235375c3335335c3337325c3337357e735c3337325c3337365c3237375c3235375c33373024712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f565c333730545c3032345c3337307e44485c303234347763715c3031323e4c5c3337315f2a5c3337345c3233345c3235375c3331335c3331315c3335355c3230315c3331305c333036535c333132635c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337325f5c333032455c3030325c3330365c3337315c3032325c3031305c333031495c333432245c3235325c3336325c32333128305c323737215c3331325c3334313a5c3336315c3336377a5c323134657b705c3231375c3336375c3235335c3337325c3337365c3237375c3235375c3233375c3333325c3336307d4e4c5c3333325c3031325c3337335c3234365c3237375c3031335c3337365c3233375c3332375e5c333536285c3030305c3031325c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336327a5c3233375c3230305c3030365c3331302d225c333032455c3230305c3233375c3237325c3336325c3236325c3234375c3336375c3237355c3032305c3335345c3335335c333632673e5c3232315c3336355c333433317964505c3030305c3030335c3234355c323534717c5c3336315c3336305c323530465c3331375c3336355f2a5c3337365c3335375c3232355c3334335c3235376d5c3234335c3232355c3330375c3331315c333334785f545c323133445c3332322e2f5e5c333335215c3231365c3330325c333335645c323232385c333234305c3330326e7c2f5c3331303a5c3030355c3335365c3137375c3230373c5c3030305c3033323f755c3237336a7e5c3337313928455c323731685c3232365c3234375c3232375c3337305c3231335c3336365c3230345c3336315c3232375c3230337e2e5c3337305c323237535c3336305c3337365c3235372d5c3233343f6e685c3233325c3333335c3331325c3031355c3030335c3030345c333034605c3031305c3331325c3232315c3230365c3031305c303131235c3033305c3336365c3330305c3333335c3335333e5c3033345c3337355c3237365c3334355c3332345c3335345c3032325c3333335c3330355c3233325c3031305c3230325c33353163315c3236365c3234315c3234345c3337345c333033712a415c3031305c3335335c3232315c3230325c323532772b763c5c3030325c3030315f5c3231375c3234375c3232315c3235366e5c3334365c3237315c323231405c323332595c3031335c3331305c3332315c3330365c3030365c3033305c33343321705c3230332a715c3331315c3335355c3231365c3333305c333731615c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336335c3332305c3330345c3332345c3230345c3233345c3232335c3333375c3337325c3337365c3237375c3235335c3337375c30303039515c3334325c3033345c3330375c3031355e556955765c3232336e5c333137555c3235335c3237365c3333353e563e5c3333345c3332365c323736275c3337307b5c3330365c3232365c3231365c333332365c32353369772b5c3234345c3237335c3334335c3333335c3334355c3331305c3030365c30303365515c323233235c3232303a5c3030305c3030365c3031374d5c3237335c3232335c3331355c33363527373746415c3033323b2c5c3234305c3033315c3030347b715c323237435c3230355c3033335c3031305c3333327d5c3236305c3030365c3332315c3332335c3033315f5c323333235c32313444772a5c3031305c323130205c3032335c3033325c3337355c3332335c3336325c3337345c3235335c3336325c3336325c323734727b635c3236363e5d4d375c3330345c3233325c3233365c323232415c3236375c323731785c3330302b5c3330365c33323120435c3336325c33343154327d5c3333375c323234645c3336365c3333323a606d5c3335355c323036393b732f5c3237305c3337336c275c3033352d5c3032362e5c3231375c3331363f5c3334345c3333375c3335327b5c323134505c3030305c3030335c3234355c323534717c5c3336315c3336305c323530465c3331375c3336355f2a5c3337365c3335375c3232355c3334335c3235376d5c3234335c3232355c3330375c3331305c333530555c3234335c3031325c3336315c3333335c32353438645f5c3232315c303130285c3031375c3232355c3232355f5c3333355c3334345c3235365c303037275c3236365c3332315c3331325c3334335c3334345c3336325c3231333f5c3231317a5c3232355c3236305d5c3336365c3232366e5c3032355c3232372c5c323630605c3235363661575c3031335c3230325c323737205c3331315c3330375c3033305c3335355c3230315c3236366f5c3337305a5c3032375c3231315c3331347a6d5c32333424325c3334345c323534445c3335345c3330304c2a5c3337345c3234332b5c3336322e4f6c765c3330305c3333335c3332315c3336355c3331324d5e5c3337375c3030305c3332375c3336355c333735775c3337325c3033305c3336315c323236525c33343377292f2b335c3332355c3334315c3237305c323335625c303333635c3333305c3233335c3234335c30333340615c3334355c3231375c3333355c3337345c3235323c5c323736575c3232365c3334345c3336345c333037515c3331365c3333345c3233375c303232785c3334362d5c3030365c3332305c3236345c333031565c3334355c3336365c3236305c323035376e5c3331315c3333327a5c3032345c3337335c3237345c3236305c3331375c303337775c3236315c3331365c3333372a5c3237335c3336315c3331365c323535745c323333555c3334335c3236335e5c3030315c3337332c214a5c323334205c3030314e5c3331345c3334335c3334355c3033345c33343463685c3335315c3230315c3236375c32333739795c303332575c3030375c333134245c303036705c323731205c333431465c3030315c3333335c3331325c333630327b635c3236363e5c5c2a63635c3236345c3031375c303133305c3334335c3231327c5c3231365c3033305c3031326f5c3233315c3336355c3232365c3331335c3334345c3233335c3237375c3331375c333536655c3333356b565c3237315c3332375c3236356b5c323335465c3335345c3231375c3236344c5c33373176445c3033304c5c3335355c3337315c3032375c3031303e5e3a5c3336365c3330376c7c5c3237315c3336315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f265c3336375c3335335c3337355c3137375f5c3332375c3137375c3331312739545c3232335c3233345c3333355c3333335c3332355c3237365c3335355c3337375c3030305f5c33323752385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372b5c3335355c323535775c3331345c3231315c303234416466545c333034695c33313027685c3031325c3237372f2a70327b635c3236363e56475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336355c3137375c3230303f5c3031335c3334355c3336316e5c3237305c3337325c3233345c3232365c3335315c3032365c32333766425c3337315c3233365b71295c3031325c303234265c3032335c3031345c3032375c32303639235c3234305c3335315c323032534a5075665c3234325c3233365c3337375c3030305c3332375c3336355c3337355f5c3237332e5c333031545c33313471505c333033535c3337334f5c3335365d5f5c3331315c3137375a5c3335335c3335315c3333365c3030315c333630385c3236365c3332335c3236345c333733385c3335355c3334335c3230342c4a5c3230375c3331324e4b30604a5c3232325c323430375c3331345c323335385c3331365c3333375c3334315c3031324a5c3337355c3031355c3334305c3231375c3030335c3232345c323136385c3337345c32323556724e625c323134295c3337315c3336335c3336375c3031365c3332305c3033335c3334365c3231375c3233365c3233315c3333327e5c3334325c3235315c3333305c3237365c3031335c33363040545c3231355c3032325c333337665c3337345c3233375c3232315c3030303970735c3236305c3335355c3030315c3230365c3335305c333732715c3332305c3337355c33323552535c333330745c3033355c30303120505c3333365a5c3330365c3237315c333334705c323333795c3331346e305c3235355c3033305c3335365c30313024635c3234305c33343061563f5c32353049255c3234315c3337353b5c303130465c323334234e5c3031325c3331322a5c3331335c3332315c3032363c355c3234375c3031335c303130365c323133785c333230655c32333378425c323134375c303034385c3030305c3234325c3336355c3335375c3335365c3234335c3230315c333637536a385c3332325c3033305c333236385c33323422285c3031325c3235325c3234335c3030305c3030315c3332305c30303144715c323434315c323534715c32353044505c30323555465c3030305c3030335c3234305c3030325c3233354c5c3234305c3235375c3331325c3237375c3333325c3236375c3330345c3230335c3330353f5c3033375c3337345d725c3237305c3333316b742c5c3030335c323432723c5c3234305c3236315c3232315c333637795c3030345c3234315c3331315c3331375c3336325c3334335c3336355c3033335d5c3332355c3234305c333230344d43535c3237313b6d5c3235345c3235355c3334345c3237305c3232345c3334345c3031342a29635c3332375c333330575c3334333e5c3234377b2e5c3235335c3235335e5c333532375c3030335c333735265c333532765c323332695c3032355c303036775c3236315c3030345c3230315c3230345c303331535c3333345c3336365c3330376c7c5c323736563e5a463f5c3332375c3336355c3235315c3337315c3230375c3033345c3334323968515c3330335c3235365c3235355c3237375c3237315b5c3336352a475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323736355c3337375c3030305c3235375c3335335c3337325c3337355c3137375c3033365c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3332355c3337365c30323669425c3332375c3330335c333535742d5c3332315e6b5c3230355c3337315c3232353e5c3335325c3230335c3033305c3330325c3337365c3335375c3232355c3334305c3334345c3337375c3030305c323632395c3033305c333132794c712c672b5c3033305c3231345c3334345c303032513e5c3335315c333731465c3332355c333731795e393d5c3236315c3333335c3033372f5c3237315c3337305f495c3033325e5c323033635c3031325c333333465c3231345c323432225c3333335c3032335c303333495c3336325c3231315c3031335c3337335c323736475c3033345c3233375c333636472b5c3231375c3232335c3332315c3330312b5c3331355c3237335c3336345c3337365c3237375c3235375c3335315c3337365c3230375c333031386f6b5c3231375c323335775c323634235c3337305c3237353f2b5c3233356f5c323035745c3335337b5c3231335c3236307c5c3236345c3230315c3331325c32323528225c3330375c3232365c303134433b49405c3031325c3231355c3235335c333133635c3234305c333435765c3334353e5c3230375c3337307b62455c3330325c3331325c333436245c323236225c3031305c3330347e5b5c3030355c3336325c3232375c3232315c3232345f5c3237335c3236357272315c3231345c333436305c3234375c3331335c3336315f5c3030305c333331795c32363730275c3333315c33343144565c3231355953205c333036707e5c3334335c3030355c3335355c3230335c333530715c3331375c30333377275c3332313f5c3031365c3336345c3334325c33333761492d5c3230365c333232615c3030315c3231302854615c32303128425c303136725c3031305c3334336e304e5c3030365c3333355c3331315c333535235c3336365c3337375c303030347a5c3331365c3231376b5c303234565c3335305c3335335c3033365c333331425c323530255c3234325c303130575c3334344c5c3230315c3336322e475c3331325c3237355c3237325c323134715c3231345c3031355c3033325c3231365c3333353c5c323533785c3232335c333133485c3236365c3235305c3033365c5c5c31373775785c333530385c3033345c3031375c3234305c3235312a5c3331315c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c3032335c3234357e4a5c3337365c3332305c323736273e315c3337305c3333335c3334335c30333557795c3232315c3031365c323433255c323734525c3231305c3331303e5c5c6562405c3030315e5c323035635c5c5c3233365c3333365c3333305c3337315c313737547c6d5c3334325c3030315c3334313f5c3030365c3335335c3237325c333331505c3334334d5c3236305c3233365c333633695c3033315c3331375c3232375c3033333e3f4a5c3337346d5c3233315c3333325c3334325c3335326b5c3233315c3032345c303131647d5c3332323a205c3334315c3231365c3333345c3230355c3330325c3031345c3235315c333037275c3236363b635c3334355c3336325c3236315c3336325c333232313f2b5c3334335c323534455c3235315c3332305c3330332e5c3235355c3331335c3335365c3332317e6c5c323132385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3336315c3235375c3337355c3137375f5c3332375c3335335c3337315c3033375c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3331305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d5c3237375c3330315c323332595c3332335c32373435605c3230325c333331236f5c3333355c3237315c3333325c3233345c3235365c3334335c303333607e5c3335375c3232315c3335327b6d5c3033345c3235363e4f5c3033305c333233345c333433777d5c3030355c323734515c3231305c3334345c323236455c323137315c323436765c3232335c323634617e5e575c3231364f6c765c3330375c3331335c3335375c3236365c3236365c3235335c303334495c3236365c333331225c3031325c3332315c3231375c3232363c5c3032345c3334322f5c323235475c3232363e5f5c3232375c3232335c333333685c3337335c3237305c3337313d5c5c5c3031325c3333365e5c3233375c3332375c3336355c3337375c3030305c3031375c3337325c3233375c303032615c3333345c3235325c3332375c3330345c3237365c323131475c333537775c3137375c3232323b4f5c3030345c3333314a5c33363246225c3236375c3230346d5c3333303c5c3236345e636d5c3234375c303336595c3330305c3335315c3230335c333036575c3231367e5d5c3237335c3232305c3337355c3234363c5c3033315c3337355c3235335c3336305c3236325c3330375c5c5c323135364b5c3234334b5c3032325c3236365c3333305c323736615c3033345c3234302b5c3030315c3336325c3031347c5c3331325c3233315c3033305e5c303031385c3033337e5d6f5c3230375c33373274515c3237355c32343379495c3032335c3030315c3032332c7b5c3031315c5c5c323037615c3230343b3b5c3030304f5c3234365c3032305c3233365c3031305c3331347e5c3333353f5c3230315c3335355c333734695c3334305c30333557405c3031325c3232305c3337375c30303068585c30333355535c3032375c3331325c3234345c3236335c3030342a42762377395c3033305c3231375c3235375c3033315c3231335c3332325c3235315c303035525c3031365c3033355c3331375c333233333c5c3033325c333037605c3335325c3334315c3233375c3333324f5c3335375c3333357e363f305c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731665c3237315c3332335c3333374c5c3237345c3233365c333336585c3031355c3237345c33363048625c3232354478315c3236305c333030283e415c3330375c303330275c3236363b635c3334355c323036385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3331345c3337313f5c3335335c3337325c3337365c3237345c3337375c3030305c3233305a695c3236345c3337375c3030305c3235375c3335335c3337325c333633235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3330365c323337775c3335365c3337345c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232355f5c3337325c3337365c3237375c3235375c3332355c3137375f5c3332375c3336355c3337375c3030305c3030375c3333325c3337345c303231795c3337355c3235315c3334315c333133495c3337345c3231305c3230345c3232315c323732425c3334355c3032335c3335365c323235315c3031345c3031375c3333355c3336325c30313050495c3335355c3230315c3331325c3334335c3334345c3333335c3231325c3030305c303030745c3236355c3231362f5c3233363e5c3032355c3031305c3333315c3337365c3235335c3334355f5c3333355c3336325c323734755c3335355c323634725c3237305c3337313c5c3331335c3334314d5c3335325c3333336a5c3032335c3333315c3032345c3231355c3030345c3237335c3033315c3032342f2a5c3330315c3232332a5c3233375c323733395c30333357245c3336315c3231355c3230335c323436325c3237365c3233335c3032345c3030305c3030305c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336327d5c3033355c3031325c3233365c3332325c3233325c3232333f5c323434785c3137375c3033355c3336355c3337345c3236365c323235575c3237325c5c5c3235375c333235695c313737575c3237375c3331345c3335325c3237345c303333705c323133244a225c3231322d5c3230315c313737775c3334355c323630315c3232305c3230355c3236325c3230376a5c333430285c3334335c3235325c3336355c3335325c32343577275c3332313f5c30313635345c3230315c3335355c3237345c3237355c3231345c3231315c3236315c303336325c323035485c3333305c3237335c3231365c303131405c323730525c323730395c3031325c3030315c3337365c3335315c5c5c3234375c3331335c303332525c3335345c3232337a5c3333335c3234342a5c3030305c3330365c333030545c33303676265c303235725c3230332b5c3330375c3337363a5c3030375c3236325c3337335c3235375c3230305c3336355c333037635c3237322444655c3031345c33353134405c3030305c3030305c333032215c303337205c3330315c3330325c3334373c723e5c5c6d2b5c3033374e5c3234375c3332305c3236345c3231365c3332375c3336365c3236325c3336315c3230355c3236365c3230335c3337333a6b5c333436365c333632245c3237355c3032305c3335315c323631475c3032325c323230373b2e5c3336345c303331515c333030405c3334305c333430646d235c333435205c3334335c3336335c303136385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3333315c3333375c3236375f5c323133524f5c303131784f445c3231342e275c3237327b5c33323324315c3235365c3031325c3234322c485c3030315c303130385c3337315c3233305c3033365c3233353a295c303333635c3337305c333036385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3230355c3231345c323337355b76475c3334305c333334655c3231305c3336365c3333315c3233335c3234375c3337345c3232314b5c3335375c3332375c3336355c3031305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3230325c3337375c3030305c3332375c3336355c3337357e5c3237375c3031355c3337355c3137375f5c3332375c3337345c3033355c3137375c3030375c3335315c3330325c3335335c3330345c3333326c695c3031305c3033375c323737425c3334315c303036365c3230315c3236345c323235525c3032335c3232355c3330325c3336355c3336365c333532315c3336325c3337337c505c3030305c3235325c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336327c5c3337375c30303063345c3233326c5c3335333d5c323631365c3332325c3234315c3033373c2b5c3331325c3033375c3232375c3230355c333731795e5c3030373d5c3236315c3333335c3033372e5c3230325c3337305c32333355535c3237305e4b5c3033365c3031325c3334375c3331335c303337705c3337345c323330555c333731395f5c323235795c3335355c323634745c3330375c3331335c3333375c3230375c333034465c3232346c5c3336356f5c3337325c3337365c3237375c3235335c3337355c3336375c303137715c3031365c303333265c3330335c3331365c3233354a725c3232345c3234345c333537756d5c3235345c3235355c3332375c3332375c3335373d5c3331325c3030343162485c3235355c3332325c3030335c3237315c3030315c3333305c3230345c3032345c303034445c3031325c3235375c3335365c333632575c3030335c3030345c3336365c333332395c5c7c5c323232432c5c3331315c3031325c3231305c3334335c3336325c3234335c3031355c3033305c3333305c3230305c3230315c3033305c3337355c3333375c3331325c3234335c3331335c3337335c3237302d5c3331376f555c333437675c3230345c3235375c3231315c323635553b5c3230355c3334345c3236315c3334305c3235367c5c3236315c3336375c3031375c3331315c3230355f5c3232335c3232355c333731575c3233365c333333474c7c5c3234325c3337305c32333355535c3237305e4b5c3033365c3031325c3334375c3331335c303337705c3337345c323330555c333731395f5c323235795c3335355c323634745c3330375c3331335c3332375c3336355c33353076675c3332355c3137375c323537383f5c3337315c3336332f5c3330335c3337345c333137795b5c3235335c3232374d5c33333359725c3336315c3334345c3031355c3333314c5c33373179515c3233305c3337315c3033345c323636495c3335315c3335325c3237345c3335345c3032365c3335325c3334355c333233765c3332365c5c5c323734795c30303376533e5e54663e472d5c3232327a7a5c3235373b3c5c3033317c4d5c3235325c3235315c3333342f255c3231375c303035735c3334355c3231375c3237307e4c2a5c3337345c3233345c3235375c3331325c3237345c3336365c3333323a635c3334355c3032375c3330345c3333325c3235325c3233355c3330325c333632585c333630573e585c3337335c3230375c3334345c3330325c3235375c3331315c3331325c3337345c3235335c3331376d5c3234335c3234363e535c3335335c3336305c3335345c3033375c3335335c3331365c3031335c3337367c5c3331335c3336305c3337375c303030335c333336565c3335325c3334355c333233765c3332365c5c5c323734795c30303376533e5e54663e472d5c3232327a7a5c3235373b265c3236325c323332795c3333315c3231335c3235365c33323538245c303232465c3332335c3236354e5c3032372832396e4f5c3137375c3331317c5c3333375c3334315c3233355c3330355c3336365c323435255c3335355c3330355c3330335c323331635c3231355c323432405c323733465c3032305c3232364c5c3230355c3337313a615c3030373c635c3030335c3232315c3231345c3235375c3234345c333530366b355c3331335c3032316a5c3232315c3030315c303333375c3331305c3234354a62243b575c333637605c3232355c33373179275c3337335c3234305c303232315c333632765c3332325c3235315c333535615c3331345c3232315c3336365c3337316e3a5c3033315c3232365c303236385c3237327171525c3237355c3235375c3334345c3335355c3337325c3033365c3331335c3334305c323133595c323431625c333232435c303334602b5c3231355c3332305c3234365c3332342d5c323730645c3231375c323234605c3233345c3031345c323136315c3332335c3233355c323733625c3336375c3237335c3033375c3031315c333332785c3233335c3330335c3337325c3234365c3232375c3235305c3333312f5c3333302f605c3233365c333232705c3234345c303035657c5c3030335c3236346c5c303034375c3030345c3232335c3330365c3031365c3030363e505c3236315c3337305c3333375c323032345c3331305c3336365c30323448622a5c3030345c3331355c32373635285c3331325c3333335c3030335c3032315c3337365c323534715c3232355c3337315c3237325c303030535c303337205c3033304f5c3234305c3237342f685c3232365c3336365c3334375c3331335c3231325c3033355c3234315c32333332226c2a484c5c3235305c3033335c3032375c323730205c3337335c323536303e5c3335326d5c3237315c3335305c3331322a516a5b335c3336322f5c3330377e5c3031315c3237325c333730775c3334334d675c3330335c3332375c3236315c3235325c5c5c3335315c3236374d6e5c3335375c30323270405c3333335c3236345c3234375c3331335c333132325c323035395c333534315c3332335c3033372f3f5c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3335376f5c3333335c3234375c3334302c5c323336245c3332335c3234335c3337305c3230315c3234315c3333325c3030365c3237375c3332335c323431315c3335325c3234325c3032345c3033335c3334345c3236375c303330224c635c3233355c3233345c3230363d76605c3334345c3030345c3334335c3334305c3233305c333432585c3331364462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e665c323635374a6e2f5c3337325c3337365c3237375c3235373f5c3334365c3331345c3335332d5c323336575c3231345c3233355c3030375c3336305c3335375c3032375c3333353d5c3237365c3335355c3233375c3233375c333432475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237305f5c3337325c3337365c3237375c3235375c3332375c3330325c3337365c3237375c3235375c3335335c3337365c3031315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232365c3335365c3231355c3235315c3333345c333530373f685c323632225c3333355c333031505c333333235c3031343f5c3230375c3031325c3030314e575c3230315c3331376c765c3330375c3331334a385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232365c323433275c303237745c3337375c3030305c3235375c3335335c3337325c3335375c3234353a5c3236335c32343335525c3232345c3233325c3232325c3333315c3235355c3033375c3336355c3337357a5c333732665c3230355c3336312a5c3331355c323232345c3237375c3236334b49555c323230345c3332305c3330375c3232345c5c5c3033305c33373050235c333136305c3230335c3233367e5c3335305c333434606d5c3335335c3236345c3333354b4f5c333234406b265c323634725c30333630565c3032325c3031315c3231375c333735575c3331325c3234335c3331335c3331365c333334295c3334345c3337375c3030307472315c333632782c712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e57425c3230325c3030365c3031365c3231335c3334345c323630232d5c3033325c3336325c3230375c3334355c3334317e5e575c3230315c3232335c3333335c3033355c3236315c3336325c333637435c30333335652d5c3137375c3235375c3335335c3337325c3333375c3335375c3236303c695c3231355c3330335c333035435c3032315c303235512e5c3237333f5c323735695c3337305c5c5c3337325c3032322840505c3335316b5c3033345f3c7c2a5c3032315c3236335c333735575c3331325c3237375c3237335c333435785c3335335c333333685c333435715c3336325c303231405c3030305c3031365c3232365c3236315c3330355c3336335c3330375c3330325c3234315c3033333f5c3332357c5c3235335c3337335c323736575c3231365c3237355c3236365c323136575c303337275c3230345c3333325c3335335a5c3230355c323330515c3032355c3333345c3336305c3235325c3232355c3334315c303131215c3031375c3331335c3230355f5c3232375c3232355c333731473d5c3236365c3231365c3233305c3033336f415c3334333d665c3333345c3230325c3232374130573b60465c333332465c3333345c3030355c3331347c5c3235375c333132395c3335355c323634745c3330305c3333335c3332345c3236315c3332307b5c3234367d3d3e3a5c3330313f5c3231365c3232345c3232375c3234355c3233375c3335325c3237375c3235375c3232315c3335355c3232316f554748445b4a205c3031325c323434796a7c5c3237345c3234325c3337365c3335375c3335365c3336355c3331375c3332335c3235305c3337365c3031335c3233325f5c323337392a5c3236305c3334315c3030325c333437625c3230335c3337335c3236305c3032314e5c3032346c5c303331515c3336335c3032327b635c3335325c3032375c3231325c3337307d777d5c3235325c333531325d5c3333355c323532395c3032375c3031335c3033325c3232355c32303557605c303336575c3031335c3236363f5c323331785c3033345c3336365c333330395c3033305c3331325c3336375e5c3032375c3332335c3334325c3237315c3237365c3030305c3333335c3234345c3030305c3235315c303337226d315c32313729785c5c5c3234305c3331325c3231355c323433245c3232315c333637464a5c3334335c3334345c3335365c3230345c3332345c3334335c3331365c323636675c3333365c3334305c323631505c3330375c3334315c3334315c3231315c3234365c3233325c3231345c3232355c3332355c3336375c3236375c3333367b775c3230335c323535265c323236225c3330325c33333541465c3232347c5c323033245c3030315c3236375c3337355c3230307a273d5c3030325c3335355c3330365c303036365c3234375c3332315c3033365c3032325c323635486d5c3031314b785c3332305c3030375c3232335c3334375c3031335c3236355c3230313b725c3030305c3333323a5c323230735c333530545c3031342e36275c323037785c3031365c3330325c3033335c3232365c3331335c323330435c3231355c3332315c30303648425c3232355f285c3030365c333036505c3031375c323237605c303037385c3334357a5c323436315c3033375c3237365c333530765c3235335c3031355c3236325c323633225c3337315c3330305c3030315c323337235c3331335c3333325c303132275c3331323e555c3331375c3031325c323731385c3335323a2e5c3030325c3235365c323533435c3235305c3332345c3234325c323132295c32303051455c3032345c30303051455c3032345c30303051455c3032345c3030305145555c333235355c3031305c3236345c323335325c3335365c3336367244365c3332305c3237345c3331375c3231365c323733545c3032325c3137375c3232355c3030326d25767e5e7e5c3332365c333736255c3337375c3030305c3230345c3234335c3336365c3230305c333631545c3331325c3330315c3234325c3236325c323335745c33363464504a5c3337316a5c3231325c3331323e535c32323058364e785c3335315c3330363e5f5c3033335c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3234355c3334325c303135564f5c303230785c323133545c3332355c3334375c323135635c3237305c3237365c3237325c3232325c3334365f2d5c3030375c3331325c3335365c3330315c3231325c3235365c303230657d4f5c3033305c3330376c7c5c3237315c3236315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317e52525c3334365c3232335c3232375c3137375c3335335c3337325c3337365c3235375c3337345c3236355c3231335c3235375c3336355c323334454a5c3337375c3030305c3331345c3333335c3337335c3333355c3337375c3030305c3235375c3335325c333434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3032375c3337365c3237375c3235375c3335335c3336355c3334355c3337365c3237375c3235375c3335335c3337365c3031375c3235357c5c3031365c3336305c3230315c3332346c5c3236356d455c303236385c3237345c3234375c3231363f5c333635635c3030336a5c3335372a5c32343767235c3334355f5c3331333c5c303034253d7b4d5c333630215c323133505c3032315c3231305c3334335c3331315c333731405c323031365c3236325c3230325c3031325c3230305c323731515c3337375c3030303c5c3232372a483c605c3232355c3333305c3333333b5c3137375c3333315c3234375c3334315c3233345c3236307c245c333230655c3337332d5c3237375c3333322f5c3230335c3333355c3031305c3336365c3231345c3230325c333136766d3b4646225c3231345c3334345c333732755c3030315c303333675c3235335c333331785c3030335c3331325c3233365c333337655c323632225c3233355c3332305c3335365c323035705c3330355c3236315c323134282a3a5c3030345c3231372a485c3337335c32373025765c3236365c3331375c3234355c3330335c3235365a51475c3336345c3231375c3031375c3334315c3337365c3235355c3232355c3332305c3234375c3332355c3235335c3337375c3030305c3334305a5c3337365c3234365c3030375c3230325c3237345c3033335c333434415c3337335c3333305c3334335c323035725c3331375c3237355c303234295c3030315c3230315c333131535c3236345c3030335c333633475c3331305c3331305c303037693f225c3235315c3333315c3335355c3233365c3032365c3236335c3231365c3333325c3333305c33373171435c323637735c333436445d5c323435495c3031304a5c3230315c3236317b5c3230325c3031375c3234315c5c60636a62595c33373066355c3237335c3231315c3331355c3236325c3234305c3030355c3033377a425c333130792338215c3030365c3031305c333336795c3330305c3330365c303136365c333430793d5c3233355c3234355c3237325b5c3330325c3235325c3236305c3330375c303031206e485c3237365c333530205c3030315c3330315c3330305c3331365c3030305c303030715c3332305c3031325c3335305e675c333230326a285c323434275c303033345c333034785c3230375c333535775c3336315c3230335c3337365c3032354f5c3330325c3331335c3231305c3335345c33343778755c333135645c3236355c3232355c3232334248785c3330315c3033375c3237345c3232345c303230385c3333325c3031305c3033315c333534594f5c3033305c3331357e5f5c3234344a5c32303770415c3033315c3331305c3030345c3234327d5c3332335c3336325c3337345c3235335c3336325c3336325c323734727b635c3236363e5f625c3337355c3235323e2d5c3137375c3330325c3333335c3337305c3236355c313737796b235c3236365c3231335c3234365c3033375c3335345c3337335c3030335c323032725c3231325c333337335c3235305c3333335c333232465c333131275c323536365c3230335c3336377e5f5c3033345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3336335c3233305c3233325c3237365c3332365c3234355c3332365c3333375c3332375c3336355c3336377c5c3337375c3030305c323336785c323233345c3337365c3332335c333037495c3330315c3337335c3232305c333637575c3335325c3337366f5c3336305c3236375c3331345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731792f5c3337355c3137375f5c3332375c3335335c3336325c3237375c3332375c3336355c3337355c3137375c3330315c3332325c3336305c3332375c323037665c3336315c3030365c3236336d5c3234375c33333246235c323236565c33303332275c3337325c3236305c3032345c3032365c3330375c333132325c323431545c3232325c3137375c3333315c3335355c3231375c3232375c3335325c3231355c3030375c3334315c3231315c3236325b78605c323635455c3236375c3231317c5c323337325c3031305c3336305c3330335c3030302f5c333637475c333637635c333130385c3335315c323032576b6c5c3230335c333636435c3337305c303335255c3330365c323231275c3231335c3335366c5c333432335c3333365c3032335c3030365c3233375c3032335c3235325c3336305c3231335c3332355c3332305c3335355c3331372f5c3033365c3332304e3e5c3334335c3033375c3237325c3234345c3234375c3332325c3232363f5c3031375c333134725c333030525c3332355c3032315c3031365c3335305c3231335c3330325c323730255c3237326141515c3231345c3030355c3231345c303235247d5c3333345c3032325c3237335b675c3237355c3230345c3234355c3331335c303136775c3237333f745c3334315c3031345c3236335c333532783f5c3235345c3331357b5c333635355c3336345c3231325c3333335c3335375c3333375c3332325c3330365c3033375c3230323c5c30313656385c3334335c33363255595c333131395c323132305c3234375c3334375c3331375c3333343b406f5c3233323e7a67695c3337335c3231325c323437675c323635786b4e5c3032365c3032306d5c3032365c3336315c3234305c333133365c3336305c3230355c3033306e5c303130705c303031455c3335335c3333375c333335475c3030335c3335365c3234367e5c3232355c3234305c3337355c3231304734505c3330365c3233315c3232313c5c3331375c3333355c303230482c5c3231345c3030305c303036315c3231345c303232493d385c3335305c3237305c30333657516e5c323336555c323734495c3334355c3234345b545c3031372e3f5c3237325c323734745c3033345c3031365c3030375c333230575c3234307d5c333431255c30323451405c3030357e6d5c3337365c3333365a725c3333315c3337347a5c3232325c3334302053735c3234375b5c3331325c3332322a5c3033355c3330345c3334345c3234375c333637795c303037605c3030345c3334375c3231345c303136785c3337315c313737492b5c3336335c3334335c3337365c3031325c3033335c3234365c3233303e2d5c333530575c333032305c3231313e5c3231345c3232315c3233315c30323141625c3331333c5c3233315c3033355c3031375c3030345c3032355c3030345c3337325c3030315c3335315c3232315c3334375c3334335c3137375c3230355c3336333e5c3033335c3231345c3234315c3331355c3232355c3236375c333332495c3337366b5c3336353e555c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317c5c3033335c3337375c3030305f5c3332375c3336355c3337325c3337365c3032315c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3234375c3337345c3031355c3332315c323233505c32333758545c3336325c3234315c323236245c323132425c3237335c3030375c30303179214e5c333136475c3331325c3234333d5c3237325c3336305c3032345c3232345c3336335c3031305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237365c3336355c3337335c3033325c333330365c3234335c33363123515c333233625c32303236335c3335315c3331345c3334323d5c3230335c30303244785c3231325c3030353b395c3033365c3337315c30303060675c3033305c3337317a5c3236305c3331375c3336375c3332315c3236375c3336355c3337355c3137375e5c3137374d5c333033353d5c3233366f425e765c3337335c3332335f5c3235375c3336355c3332375c3236325c3137375c3030335c3233305c3031345c32343144315c3233305c32363126522c61475c3336305c3231345c3234375c333735315c3033315c30333546395c3333335c3236315c323636545c3337305c323131663c5c3033375c3336305c333033565c323230625c3032365c3233355c3032365c3331315c3030305c3231345c3232346c5c323730525c3235335c3336325c3231347c5c3230345c3232325c3031374d5c32373537295c3336325c3237365c3233354f5c303030655c3334325c3231365c3033335b63205c333731425c3235305c3330312c5c3031315c3333335c3230315c323634635c3337355a707a6c5c3334375c3033335c303337675c3331365f5c32363654717877405c3336305c3336365c3232315c30333224325c5c4e5c3332335c3237375c3232325c32343724475c3337335c323630315c32363060605c323530205c333632365c3336335c3230325c323434275c3236355c3231315c3232372d29335c3336365c3331345c3337375c3030305c3032315c3336356c5c3235365c3237354b5c3335335c3331325c3332375c3333375c3234325c3337345c3331375c3232335c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3233335c3237375c3336355c3337355c3137375f5c3235375c3336336f5c3336355c3337355c3137375f5c333630485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c3237375c3336355c3337355c3137375f5c3235315c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334352f5c3337355c3137375f5c3332375c3335325c3137375f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314b5c3337375c3030305f5c3332375c3336355c3337325c3233375c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3331305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d4b5c3334305c3232375c3335345c3334375c3334326f5c3231345c3237325c3233325c313737675a5c3033352f4647555c3237305c333236255c3230305c323330625c33343541485c333736415c3334365c3033363a5c303032315c3231364a5c3230315c3232355c32373046555c3033372c755c3137375c3332375c3336355c3337356b5c3332315c3230375c3330335c3332365c3330355c3332345468455c3331324f5c3234325c3337365c3237375c3235375c3331375c3233325c333730635c3336305c333033545c3337305c3232375c333432255c333233745c323533715c3032325c3234305c3336332e5c3235365c323034794b685c3330305c3033315c3330375c333132375c3031342f5c3332375c3231365c3330305c3032325c3237375c3234335c3033375c3031355c3337365c303136695c3233365c3031375c3332306c5c3236345c3237353a5c333231205c3236375c3236365c3030363d5c3334365c3033355c3337335c333136765c3236312760604e5c3334352c3e5c5c5c3032345c333036415c3030375c3331325c3335305c3237365c3032315c3337345c3031375c3332305c3337365c3032305c333530515c3335317a455c323434705c323531215c3334365c3237305c3331325c3237345c3232333028545c32363128395c333731485c3331305c3330375c303030605c3031375c323234275c32343243656f6e5c3330315c3234325c323032385c3231305c30333341445c3030335c3030335c303030635c333632555c3033375c3336305c3032315c3335315e5c3337365c3033375c3031375c333534555c3333365c3335345c3337355c3335335c3230375c323632285c3334355c3032345c3233345c3335326b565b5c3237365c3333364b5c3336355c333536615c3335305c3333365c3033355b362a515c30323363655c323636285c3333335c3233345c3330365c3334335c3030305c3234305c303335415c3030355c3232375c3033355c303036315c323035585c3337325c3031305c3334334863585c333433505c3231305c3234302a5c3235325c3231345c3030305c303037405c3030355c3032315c3330365c3232305c3330365c3236315c3330365c3234315c3032314055555c3033305c3030305c3031365c3230305c30313275765c3033375c5c5c30323451455c303030795c3031375c333535655c3334326f5c333730455c3237365c303030785c32363675705c3236325c333335405c323636285c3237315c3334355c3237345c333437585c3333305c3031365c3031375c333630335c3033375c3234303c5c3231365c3234335c3336325c323632385c323236335c3232315c3033305c3231345c3230325c303031285c323337775c3335365c3337345c3235335c3336325c3336325c323734727b635c3236363e5f5c3237353f5c3334305c3234325c323736235c333733375c3230335c333734295c3234315c3235345c3333334d5c3332355c3336335c3333355c323734695c33313362345c3333323230785c3337355c3335315c3336345c333735323e5c3031335c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c33343063657a5c3236365c3335345c3237375c3235375c3331345c333734275c3231345c3335335c3337335c5c5c3331375c3333315c3235375c3236315c3032345c3237365c3337355c313737555c3337356e475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237345c3032375c3337365c3237375c3235375c3335335c3336355c3337305f5c3335335c3337325c3337365c3237375c3334305c3333345c3332305c3336345c3332355c3237355c3332355c3235345c3335355c323236315c3033375c323335347131445c3331365c3333345c3232355c3033305c3033305e575c3030335c3232335c3333335c3033355c3236315c3336325c333735423c5c3030365c33313123475c3033325c3330305c3231365c323035586d5c3231376e5c3030305c3334336825315c3337375c3030302c46415c333435715c3331365c3333355c3231355c3236335c3331325c3337375c303030655c3237375c3030355c3331315c3334325c3333375c3231343a6450415c30333136715c333131765c3331325c3032335c323431545c303031557e4e465c3334325c323337315c333036315c333234632b5c3336372a785c3030332f5c303234705c3333325c3333335c3033315c3030375c3331325c303235465c303131604e5c3333345c3031355c3234335c3033375c3335325c3332335c3230335c33323367385c3333305c3337333d5c3237345c3032345a5c3234365c3334355c3333345c3337355c3234335c3230315c32353072612a5c3332375c3137376a565c333731455c3137375c323333675c323236785c3030375c3330315c3236325b5c333534645c32313555225c3334305c323534715c323032315c3033312d5c3230355c303035415c3030305c303030335c3233375c3237335c3236375c3337335c3330335c3336375c31373740782f443a6b24485c3232315c3031372c223224205c3230305c323533375c3033305c333731325c3237355c3237325c3336345c333330475c3030354f5c323235535c3330335c3233365c303133585c3335355c3230346d5c3030326d5c3033375c3237335c3033315c3231315c323332315c3230365c3333315c3336325c333431415c5c5c3030365c3033315c303334635c3030375c3232305c3330305c3233305c3237335c3231375c303137597d5c3232362f5c3337305c3336375c3230363e5c3234377a455c3334355c3232315c323235435c323030362f5c5c727d575c3234305c3337335c3235315c3335315c3033375c3234345c323637735e385c3332325c3033305c333236385c33323422285c3031325c3235325c3234335c3030305c3030315c3332305c3030314e5c3234325c323132625c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230305c303132285c3234325c3230303c2f5c3336365c3332325c333631385c3336305c3333375c3330305c3031356e355c3232335c3331335c323333525c3232365c3031335c3031305c3331305c3335327738665c303030605c333437285c3231375c3336345c3033313c625c323737305c3234335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337355c3330355c3337375c3030305c3030355c3033305c333631465c3331335c3033375c30313078795c3032345c33343249655c3237375c3232355c3330305c3030345c3231355c323730445c303030605c3233345c3033355c333232645c333434635c3030335c323537555c33373076385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3331375c333433257a5c333135765c3337365c323737535c3336306e305c3330347b6c5c333232505f62297e5c3237375c323530475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323734375c3337365c3237375c3235375c3335335c3336355c3337305c3231375c3335335c3337325c3337365c3237375c3334305c3336355c3137375c3031333c3e755c3231375c3033315a24685c3232315c3231305c3030335c5c395c3031315c333637762021575c3334345c3334345c3033355c3234335c3233365c3333305c333532315c3336325c3337355c303231695c33343059235c323733685c3234305c3231325c3032332f5c3030315c303235232b5c3231365c3031325c3230355c303037685c3337375c3030305c32333643205c333632315c33313636365c3331345c3031375c3333305c3236335c3334315c3336335c3335335c3333325c3237375c32313035545c3236345c3231355c3231355c323734715a465c303331305c3237335c3333335c3334375c3333325c32303767385c3336325c3232305c333437235c3033357a29295c333635643e5c3030315f36385c3334335c3236345c323637675c3030305c323530545c30333349715c3233355c3237305c303035385c3330375c3232365c3233345c3033375c3335365c30333657636c5c3336375c3336305c3232314a5c3231325c3336333f795c3334305c3335343f5c3236315c3331325c3332354e5c3236335c3232335c313737765c3233375c3234315c3330325c3337306f5c3330337e585c30303238715c3231345c333130425c3330375c32313463645c3233342b463a605c3334345c3231347d5c3332315c3330305c3333325c3235335c3033375c3332305c3033365c3032315c3332335c333331555c3334345c3032305c3337355c3232342b382d5c3033315d5c3234375c333437535c3230305c3031325c3031345c3032335c3236345c3335365c3335315c3231345c3230315c333031505c3236315c33343178735c3330325c3235315c3031335c3330355c323133715c3033343138445c3031315c303336365c323031215c30333056585c3330315c3031345c3030335c3336375c333036365c3336362b5c3337335c3233365c3333374c5c3236335c3032365c3234345c303137295c3030335c3234325c323035775c3333325c303031535c3236315c3030365c3032375c3031305c3234315c3232345c3230355c3033345c3337375c3030305c3236325c303036385c3330325c333637245c3232325c3236323e5c3333345c3337345c3330375c3337355c3235365c3237345c3030325c3237365c3030325c3337305c3335375c3235375c30313062586c5c333635365d4e5c3030335c30333478204b5c3231355c3334305c3031355c3237353c5c333034704e785c303030745c3330365c3032375c3330355c3334335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337355c3335315c3337375c3030305c3030355c3031365c333630225c3333375c333730535c3330335c3237362d5c323036335c3334375c3335315c3336375c3030365c33303677415c3232335c3334354b5c3336332e465c3031375c3030315c3232335c3033315c3334335c3335375c333736235c3334305c3237305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323737375c3231305c32313725592f5c3335335c3337325c3337365c3237355c3137375c3233345c3237305c3231335c3031315c3336353c5c3331365c3236343a375c3331345c3237355c3033365c3237375c3230335c3332335c3337325c3332345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731795c3235375c3337355c3137375f5c3332375c3335335c3336335c3233375c3332375c3336355c3337355c3137375c3330315c3237315c3234325c5c5c3231355c303337555c3236355c323734485c3232354c5c3032325c3234335c3032305c3232315c3230335c3231346d5c333731575c3334355c333435485c3033357b635c3236363e5f5c3234365c3334305c3336305c323034735b5c3337315c3336365c3331376e625c3333305c3232335c33303724515c3337345c323435315c3232305c3032345c3335345c33353044235c3231365c3234335c3033375c3330335c3236315c3236367c5c3236315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3335355c3235375c333331515c3332335c3330375c3137375c303136205c3236354b7b735c3137375c3234345c3331335c333636374c655c3231375c3030315c333432205c3335355c3335315c323035455c3033375c3336355c3331333c5c3030346d5c3233365c3235365c3030365c3234365c3235365c3032375c3336333f505c3334307c735c3230356a5c323330393d245c3237315c3232375c3235325c3333375c333537565c3337335c3237365c3337365a5c3031375c3030345c3331316d71225c3330345c3236302b5c3235305c3334336a5c3032345c303030605c3235365c333230765c3231375c3337315c333434325c303137235c3033345c333430236c5c3336345c3233375c3030335c3335305c3236374a5c3033355c3236365c3335355c3333325f26245c3030335c3234335c333536385c3033335c3030365c3030365c3032375c3030375c3230304630795c303030475c3335305c3231315c3334305c3031345c323734515c3330336b6c645c30333728555c303330255c3230313b70365c3231345c3137375c3235334e5c3031374d5c3233345c333433635c3335345c3332335c3332325c3237345c3032345c3332365c3236302c715b222c5c323134505c3236344839605c3235345c32333728295c3332345c3031355c3233345c303232315c3236375c3232325c3031325c3233372f5c3332366a5c3334375c3335344b547c755c3337336b413d5c3235375c3231365c3336345c3031305c3334365c3030305c3030355c3332335c3231315c3333355c303232605c303036375c303232675c3031335c32363063385c3030305c3336375c30333340385c3333335c3230345c3337315c333136385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3333335c3137375c323637375c333033373e5c3031335c3332305c323734576d6e5c3235315c3337355c323335725c3332365c3236374d5c3033325c303235615c3033345c3330315c3033314e5c3332335c3033305c3334303a5c32323524635c3033335c3230375c3031325c3030365c3333305c333736245c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c333430625c333233555c3233355c3337375c3030305c3235375c3335335c3337325c3336335c333736775c3334325c323132335c3234355c323333565c3334365f5c3032355c3233325c333633565f5c3235355c3337375c3030305c3235355c3331305c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3231365c3337375c3030305c3332375c3336355c3337357e5c3237372b5c3337355c3137375f5c3332375c3337345c303232385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c303337295c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334352f5c3337355c3137375f5c3332375c3335325c3137375f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314b5c3337375c3030305f5c3332375c3336355c3337325c3233375c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3235335c3033342a5c3230372b5c3033305c3231345c3334345c303032634f5c3237327e515c3236357e5e575c3231364f6c765c3330375c3331325c3335375c3337355c3137375f5c3332375c3335325c3137375f5c3332375c3336355c3337375c3030305c3030375c3333345c3237365c3031375c333730255c3233375c3330315c3337375c3030306e5c3032315c3330375c3031334d215c3233345c3033355c3233355c3032314e365c3235315c3333315c323032335c3030315c3336375c3334333c5c303035253d735c3330325c3333365c3030365c3232325c3331365c33353124485c3234335c3231315c303236415c3230375c3231355c3033305c3031345c3231375c3232335c32313426415c3030336775236e325c3234354e5c3331374b5c333730695c3336305c3235335c3337335c3032335c3330305c3237365c3033345c3332335c3334325c3236315c3230323b5c3233305c3335345c3334335c333633235c3330375c3331346623715c3330302a5c3031305c3337315c323231783d365c3336335c3231355c3231375c3236335c3235375c3236315c3337307e23684a595c323034245c3233305c3237345c3331305c303036395c3033315c30303428283a5c3030355c3231335c333435247d5c3332325c3031315c3033335b5c3331335c3337326a705c3334355c3234375c3033305c3237365c3232363f5c3234375c3336325c3235325c303337555c3330305c3332315c3234335c333235455f5c3332365c3333325c333736252f5c3030336877365c3335375c3031365c3331305c323234645c3330365c333333446a5c303131605c3230355c3030365c3330365c3031305c3237315c333031435c3332305c3235315c333433205c3235304c5c3234375c32363469365c3331336f655c3033365c3030365c3332325c3335325c32313457605c5c5c3032305c3231325c3237305c333030555c3336345c3335365c3030315c3335355c3230305c3030305c3030335c3030374b5c3332315c3033325c333136385c323336385c3232315c3032375c333135525c3335335c3334355c3032315c3232305c3331355c303333705c323436315c3230335c3233365c3235345c3030305c3033372e3e5c5c2f5c3232355c3332335c3333335c3234375c3232356f5c30323279695c3032365c3332355c3030335c3331335c3231375c3335365c3235375c3033355c3030375c3030335c3230315c3336345c3032355c3237315c3335305c32313334315c3333345c3330325c3336314a5c32313324522957475c3033315c3031345c3031375047715f5c3233355c3337375c3030305c3236356f5c3335345c3234333f5c3330336d525c3335335c3330355e5c3032335c3236302d5c333431295c3231305c323232786d5c333234335c3335315c333136485c303035425c3230355c3337375c3030305270395c3331375c3331335c3332305c3334305c303030475c3335305c32333547716f5c3032355c3333355c3237345c3232304f5c3033324d5c3031345c323532515c3334335c323231432b295c303330205c3230335c3332345c30323158565c3234325c323533475c3232355c3233365c303236715c323234515c333136287b2a5c323332496c5c3337333f5c3336325c3335365c3231375c333035285c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3236343f685c3233375c333330755c3235356e655c3336315c3031375c3330336b355c3336325c3033375c3334365c3237305c3332305c3332335c3033335c3334333c645c333030485c3334354e5c303036505c3233345c3231347c5c3234375c3033305c3031335c3336315c3237355c3333365c3232373e5c3231377b355c3235355c3332355c3234345c32323637703f5c323235342f5c303131475c3230355c3330365c333230535c3030355c3030315c3330375c303330395c3335315c3231365c3333305c3337317e7a5c323435295c333232765c3232375c3336355c3337355c3137375e5c3137375c32303166595e2b2b5c3235325c3335315c333432235c3335305c3337323f475c3337353f2e5c3336355c3334335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323434712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5c5c6f5c3337355c3137375f5c3332375c3335335c3334345c3337375c3030305f5c3332375c3336355c3337375c3030305c3030345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c333435235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337314b5c3337375c3030305f5c3332375c3336355c3337325c3233375c3332375c3336355c3337355c3137375c333031235c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462335c3232305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337316d5c3335305c323732445c3233325c3234365c32353367636b5c3031362e2e665c3231365c3030345c3032315c3234305c333130762a5c323431575c3334355c303331535c333030275c3236363b635c3334356b57655c3337355c3137375f5c3332375c3233335c323132737c5c323533775c3337355c3137375f5c3332355c3337365c3230305c333730755c3334305c303131215c3336305c3232365c3233335c3236352149645c3231316e715c3236305c3031355c3237335c3237366d5c3234315c323636605c3337375c3030305c3235325c3033365c3334335c3033355c3230325c3033355c3233365c3234335c3334312f5c3030372d5c3235315c323133305c3230305c3235305c3330305c3030325c323130425c3231355c3235355c3236375c33343421325c3230345c3030365c303334715c32313476604c5e5c3237335c3234365c333734385c3231365c3331365c3333365c3331365c3332325c303133585c5c5c3330335c3032305c323035405c33303066655c303330425c3030365c3330315c3231375c333635715c3336315c333333615c3337335c3237335c3033335c3331335c3333325c3332323c5c303030225c3236375c333134365c3235305c3235375c3336332334705c3230335c3330363661325c3233345c303336635c3331325c3232325c3234306c5c303331205c3235315c3336325c3237365c323436315c3236324b5c3236315c3337354d5c3230355c3234325c3236305c3333307a745c3032365c333231497d5c333131225c3031375c3030305c3335305c333736585c3236305c3231355c333431435c3233372b24654a637a5c3337345c32303446395c3337315c3137375c3230375c3030305c3030304f5c303035735c3033375c3235375c333331426d5c3335345c3334305c3231315c3230305c303035235521715c3230315c3230315c323136305c3030305c3337345c3230305c3337325c3031325c3330315c333230745c3032345c323031415c3336325c333236355c3331365c3334335c3230345c3333335c33313663715c323035685c3330377041235c3033355c3030375c3030335c3031325c3236315c333634515c3330365c3232305c3330365c3236315c3330365c3234315c3032314055555c3033305c3030305c3031365c3230305c3031325c3332305c3335325c303335455c30323450205c3234325c323132285c3030305c3234325c323132285c3030305c3234325c323132285c3030305c323537285c3337355c3235315c3237344f5c3337375c3030305c3031305c3233375c3330304f5c3032375c3333355c3235335c3335345c3232367b51625c3230333c5c323233332c475c3033345c3033365c3231325c3335347e5c3230305c3233345c323134647a5c323735676b5c3333365c3033345c3332327c53606c755c323335325c333137565c3236322c5c3033345c3333335f405c3236334658743b585c3032315c3232315c33353353345c3333345a472e2e5c3232345c333533615c333532525c3234365c33353529265c3232335c333535756b5c3233375c3231345c3031315c3032325c33303672235c3032315c3233345c3230304a275c3333353f2f5c3331325c3237372f2b5c333037275c3236363b635c333435485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237375c3235375c3031315c3336302b5c3334315c323634445c3032345c3337305c3137375c3334317420605c3032355c3332315c3235355c3330375c3033345c3031375c3335367b5c3031375c333130505c3233375c3030325c3237365c30333344414f5c3230375c3337365c303237425c3030365c3030315d5c3033325c333334715c3330305c3337365c3334375c3236305c3337345c323035785c3337375c303030505c3233375c3336335c3033375c3232335c3337375c3030305c3235305c3237305c3231375c3337315c3337365c3237365c3334367e435c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3232365c3331325c3330355c3235362e5c3234325c3230365c3031303f7d235c3235346a5c3236305c3234364e5c3334335c3236345c3030345f5c3232375c323230705c3030367d5c323733635c3334355c333735734f5c3230315f5c3031355c323432205c3234375c3330335c3337375c3030305c3031335c3234315c3030335c3030305c3235365c3231356e385c3334305c313737735c3333307e425c3234345c3236335c333730255c3336305c3335374f5c3237315c3231325c3334325c3332375c3330307e5c3033325c3236365c323336265c3031355c3033345c323631695c3032365c3335325c3331304630415c3031315c323230465c3332315c3337315c3031374a6b5c3030312b5c333533215c3235365c3030355c3235377d6b5c3235375c3237315c3233325c3233365c3031325c3336307d5c3232375c3230345c333734255c323432685c3336315c3333325c3333335c3230315c3234375c3333315c3330336f5c3233305c333432505c30313144415c3232315c3230303b5c3234325c3233365c3230335c3234305c3336345c3032355c3236305c323732755c3234326d5c3333336b5c3031325c3335355c333036315c3033305c3033305c3330365c3333347e5b5c3032335c3337365c3337315c3033365c3230325c3235345c3332315e5c333032565c3332315c3033375c3235375c3330362a5c303231515b225c3033306c5c3235355c3335355c3333303450475c3033315c30303368285c32303060605c3031347e4a5c3234335c3337365c3030323d2a485c3334334863585c333433505c3231305c3234302a5c3235325c3231345c3030305c303037405c3030353a5c323132655c303035785c3031375c3335355c3233315c3336317d7e5c3033327c2d5c3233334d5c3236335c323730785c3236355c3331355c313737755c3233355c3237375c3232345c3234345c323632435c323030265c32323338385c3334315c3230325c3334375c3230325c3031335c3334347d5c333232475c323737573f5c3334323f5c3230375c3333365c3032375c3336315c3230355c333134375c3033325c3336375c323037345c3233356a5c3334325c303034315c3330352e5c323431635c3032345c3335375c3033325c3232335c3232325c3235325d495c3030305c323336702b2a5c3236315c3232345c3334305c3334335c303237665c3331373f305c3234335b5c3032315c3230355c3233355c3033343c5c32323465256b5c3237365c3233355c3337375c3030305c3030335c3336315c32373522585c3331365c3334305c323032335c3232305c303131445c3337335c3234375c3334355c333731575c3334355c333435785c3334345c3336365c3330376c7c5c3235315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3336355c3334313e5c3030357c365c3231305c3230325c3233375c3031375c3337342e5c3230345c3031345c3030325c323732355c3237305c3334335c3230315c3337355c333137615c3337315c3031325c3032335c333430575c333033685c323130295c3336305c3337375c3030305c3330325c333530405c3330302b5c3234335b5c323136385c3033375c3333345c3336365c3033375c3232305c3235372b5c333532335c333736635c3336325c3333375c3336355c3032375c3032315c3337375c3030303f5c3332375c3333345c3331375c333130785c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c323735575c3330325c3237375c3230375c3232373f5c3032325c3337347d5c3234325c3337306a5c333035455c3237345c3236375c3336375c3031335c3033345c323233247b5c3237345c3231305c3330305c3030355c3333305c3031355c323433725c323034527a5c3231375c3237335c3231363f5c3230375c333635393e5c3030357c365c3231305c3230325c3233375c3031375c3337342e5c3230345c3031345c3030325c323732355c3237305c3334335c3230315c3337355c333137615c3337315c3031325c3332325c3336305c3335375c3330325c3335375c3030365c33373043505c333733765c3230355c3334313d5c303137455c3237355c303130635c3337334e5c3233375c323437435c3030345c3233335c303136325c3237335c323231415c3330315c3333325c3237347b5c3031374a5c3235305c33343065755c3331352d5c3031355c3235305c3336303545522e5c323535645c3334337d6c5c3233355c3333325c3335355c3337355c3137375c3330335c3333365c3336305c3334375c323034345c3233375c3031325c3335307a7e5c3232335c323437585c3330315c3030355c3233355c323134295c303034285c3236315c3235305c3330325c323530503a5c3031365c323737225c3233345c3337325c3235305c3336345c323535285c3235346d5c333430205c3330355c303034515c323230305c303132205c3033305c3033305c3030335c3033375c3232325c3235305c3337375c3030305c3230305c3231374a5c3233365c3231325c3336365c3031375c3332365c3234335c3032355c3030345c3234335c303235645c3231305c3332325c333336285c3237345c3237355c32323122796b5c323631365c3235305c303333575c3231365c3030375c3234305c333430715c3335342a4a285c3234305c3234305c3234325c323132285c3030305c3235375c3230355c3137375c3334305c32343376223f5c303232782a5c3336375c3030345c3033312d6e215c3333365c303237246d5c323232335c3230315c3330315c3334305c3335365c3334375c323436303e5c3235335c33363755615c3337305c3232335c3330305c3237365c3033335c3336315c3232335b365c3237375c323430697a5c3334335b5c3030365c3032305c303335465c3331363b5c3230335c3032306c6e5c3333335c3237345c3033355c3237315c3333325c3237315c3330375d5c3234335c3332325c3236305c3235374d5c3332355c3230335c3231323c4c5c3334372f5c323236695c3230325c3233365c30323632495c3237336a5c3337345c323332675c33343354712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3335335c3330327c5c3031325c3337306d5c3032315c3030353e5c3033375c3337305d5c3031305c3033305c303035746b715c3330375c3030335c3337335c3233365c3330335c3336325c303234275c3330305c3235375c3230365c3332315c303230535c3334315c3337375c3030305c3230355c3332305c3230315c32303057465c3236375c303334703f5c3237315c3335343f215e675c333234275c3337345c3330375c3334375c3033375c3335322e235c3337365c3137375c3235375c3237315c3233375c3232305c3336315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337317d5c3337375c3030305c3336365c303331786d5c323737685c30313532275c3230323f5c3336345c3231334b5c3231305c3330305c3330305c30303158465c3033345c3030355c3331305c3033315c3033375c3237335c3331364739515c3330375c3033372f5c333337295c3336302b5c3334315c323634445c3032345c3337305c3137375c3334317420605c3032355c3332315c3235355c3330375c3033345c3031375c3335367b5c3031375c333130555c3333355c3031335c3334312f5c3230315c3337342f5c3235315c3330335c323531685c3333365c3031365c333230345c323335425c3030304457763a64305c3331335c3033302b5c3236345c333535755046575c3230335c3230335c3332335c3231325c3332365c3232365c303136745c3334365c3234345c3334355c3236315c3333355c3230305c3334305c333534465c3031375c3032354f5c3032315c3335355c3232335c333435695c3335345c3336355c3236335c3333305c3335305c3332374e5c3236344d5c3237336d615d5c3237305c333036235c3030335c3033305c3333335c3231375c333133625c3137375c333337235c333230575c3232347c6a5c3337355c3232375c333734275c3336315c3236324b5b5c323535424b5c3331352b535c3236345c3230375c3331305c3230325c3335325c3330315c3232345c3030305c323735425c323632302a475c3030305c303334605c3232305c3030305c3331375c3030335c3033365c333031457a725c3231325c3233325c3236345c3232365c3230375c333531585c3233342d5c3033346527465c323734795c3234325c333732335c3336335c3235375c3330365c3237375c3336304f5c3337375c3030305c3033357876495c3234365c3336305c3335355c3330365c3233355c3334325c303333507e445c3231315c3332365c3333325c3334345c3031345c30313636385c3333315c3231342e3e5c3337313c5c303134765c3330375c3230335c3337305c3233375c3334315c3137375c3231323c5c303035285d775c333033775c33373231385c3337315c3334355c323635605c323433207c5c3235325c333333305c3331335c3230355c3334345c3334375c323134765c3330375c3331335c3337335c3033314c5c323232245c3233314a5c3331305c3231325c3335327a5c3230365c3033315c3032355c3334375c3331375c3030335c3032375c3235345c3033355c3231375c3230355c3330355c333630565c3031325c323633725c3330335c3331355c3330335c333133755c3337305c3335335c3337305c3233375c323132495c3031325c33303472235c3032315c32323040255c3032335c3335365c3337355c3333375c3232357e5e575c3231364f6c765c3330375c3331325c3232315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c3337315c313737507e3c5c3337342e5c3336306c5e5c3033305c3033325c323032784f434b5c3336365c323334215c3237325d3a5c303231295f2d5c3337305c3333355c323637385c333731575c3336325c3033365c3232355c3337315c3331375c3334337d365c3332334f5c333631455c333734765c3236365c3236305c333333465c323232485c3235325c3232305c3330365c303234285c3333345c3330335c3030305c3031365c3233342a5c3231375c3330307a575c3031356c2c5c323531595c3236377b5c3233375c323333675c3033312c5c33363279725c3332345c3233325c3232375c3234375c3336355c3337357e7c5c323634712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372d5c3236355c3236365c323036224a445c32313040205c30323550303a5c3137375c3335345c3234335c3336325c3033365c3232355c3333365c333734215c333231345c3335335c3333356c255c3330355c3230355c3236345c33353225555c303133242a5c3330335c3033365c5c5c323734723a7c5c3231335c3337375c3030307c5c323137415c5c5c3337365c3331365d5c3331375c3233355c3234345c3237355c3235345c3332345c3032335c3333345c3336335c3231305c3234305c303130725c3236315c323034395c3030305c3233305c3332335c3335365c3233375c3232346d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c3337325c3137375c3330335c3335375c3333315c3231375c333432275c3330345c303331555c3236345c3237375c3031335c333334595a5c3233365c3236375c3236375c3331302d5c3234315c5c5c3030355c30333046755c3030355c3332345c3334305c3031345c323530275c3231365c3333305c3337315c3137374b5c3237345c3032355c3336305c3332335c3330323e5c3033355c3236355c3236375c3237315c3332325c3237342d5c3234325c3335315c3232372a5c3031305c303233595c3335315c333631445c333430675c333235545c3033365c3330335c3336325c3032355c333331635c3032355c333530525c33303129454a525c3333345c333735675c3030355c3330315c3032345c3334345c3232354c4d665c3332335c3335315c3032356f5c3330355c3333375c3336323e4c5c333730475c3337335c3030305c3337307b5c3330334f5c3033355c3337375c3030305c3231345c3335365c3330365c3237317e5c3234354a5c333331595c3337365c3335365c3332315c3030365c3032372a4e5c3332305c333536385c3030335c333730785c3033353a5c3030315c3336355e5c3233335c323436595c3335305c3332365c30323059585a5c33303365675c3030325c3031305c3334325c3236375c3236375c323134475c3033346a3a5c303035515c3230305c3030375c3236305c32353334575c3234374e5c323234295c323533455c3033375c32343260725c3333342e5d5c3031364c345c3032347b5c3237365c3235375c3332355c3335365c30323451456a7a41455c303234505c303031455c303234505c3030375c3334373f5c3335355c3336375c3334325f5c3335355c3231375c323135565c3337327264475c323434695c333231405c333034645c323231245c32313464385c3033337a5c303235645c3030345c3231375c3335365c3231365c3137375c3237335c33363334712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e5f5c3333306d5f5c333431375c3230323c415c3235325c3331375c3235315c3335325c3233365c3031365c333230755c3033354a725c3031345c3236375c3232377a64325c333135265c303030515c3237315c333331493c2a5c3231364f455c3033365c323235453e5c3030357c365c3231305c3230325c3233375c3031375c3337342e5c3230345c3031345c3030325c323732355c3237305c3334335c3230315c3337355c333137615c3337315c3031325c3336326a605c333437526e5c5c5c3333335c3233375c323237663c235c3231315c3330375c3334325c333532625d645c3237315c3233355c3336367b745f715c3337315c3031375c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3337325c3336305c3233375c3030325c3237365c30333344414f5c3230375c3337365c303237425c3030365c3030315d5c3033325c333334715c3330305c3337365c3334375c3236305c3337345c3230355c3031315c3336302b5c3334315c323634445c3032345c3337305c3137375c3334317420605c3032355c3332315c3235355c3330375c3033345c3031375c3335367b5c3031375c333130565c313737505c3233375c3336335c303336775c3337325c3231335c3231305c3337375c3030305c3233375c3335335c333536675c3331325c3233375c3336304e6f5c30313147255c3336375c323134355c3333316d625c3333335c3033325b5c3333315c3330365c333333475c3331325c3333315c3333365c3331325c323737285c3331305c30333322395c3336355c3030335c3332335c3334355c3337336d745c333533445c3333335c3236365c3332365c3032355c3333335c3231346230315c3231355c3237305c3337345c323636275c3337355c3336323d5c303035515c3336305c3332375c3230335c3336345c3033375c3030355c33333149675c3334315c3337355c3032374f5c3332305c333535245c313737355c3334305c3332336d525c3333355c3033315c3336365c3230355c333334555c3030305c3030345c33343154675c3332305c3030315c3333325c3236355c3335335c3332345c3234334f5c33333141445c33373527285c3331335c3337375c3030305c32363330705c3330325c323637765c323537775c3333355c323637725c3033306c5c3235355c3335355c3333303450475c3032315c30303368285c32303060605c3031347e4a5c3234335c3337365c3030323d2a485c3334334863585c333433505c3231305c3234302a5c3235325c3231345c3030305c303037405c3030353a5c3231325c3333305c333636425c323132285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c3030325c323132285c3234305c3031375c3331355c3033375c3333335c3232335c3330345c3330375c3330345c3033375c3033376f5c3335355c3230336e5c323133475c3236355c3230325c333035644f5c3233335c3030345c3235305c3232355c3230305c3337317a6e5c3232305c3230335c3331375c3033337a5c3336315c3336325c3337345c3337315c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232375c3336365c303137525c333730415c3334304d67525c323337515c3332343c5c3032375c3334315c3337335c333535425c3334315c3231335c33313577735c3234355c333031245c323632315c3330364b315c5c5c3232335c3330305c3335335c3335302a5c3234327c5c3031325c3337306d5c3032315c3030353e5c3033375c3337305d5c3031305c3033305c303035746b715c3330375c3030335c3337335c3233365c3330335c3336325c3032355c3334345c3332345c3330315c33313673725c3334365c3333345c3337345c3235375c3033375c3330315c3337305c3233346e2a5c323436255c3332364b5c3233355c3236375c3236335c3337335c323736475c3334343c712c672b5c3033305c3231345c3230325c303031285c323337775c3335365c3231355c3235335c3336325c3336325c323734727b635c3236363e52385c323236335c3232355c32313446415c3030305c3232344f5c3237335c333637465c3332355c333731795e393d5c3236315c3333335c3033372f5c3335335c3330327c5c3031325c3337306d5c3032315c3030353e5c3033375c3337305d5c3031305c3033305c303035746b715c3330375c3030335c3337335c3233365c3330335c3336325c303234275c3330305c3235375c3230365c3332315c303230535c3334315c3337375c3030305c3230355c3332305c3230315c32303057465c3236375c303334703f5c3237315c3335343f21595c333735425c3137375c333134705c3337375c3030305c3235305c3237305c3231375c3337315c3337365c3237365c333436792f5c333534215c3334305c3237335d5c3033335c3334305c3230345a5c3233335c333332465c3236373a5c3235355c3335345c3236375c3030345c3232345c3335305c32353056355c3031335c3232355c3033345c3030335c303230205c3231376f4c5c3031375c3234325c3232374e5c3236344d5c3237336d615d5c3237305c333036235c3030335c3033305c3333335c3231375c333133625c3137375c333337235c33323053345c3231355c3033365c333033405c3332336d5c3336345c333535325c3331325c3333374e5c3236305c3236375d5c3232305c3333325c333332445c323631455c3032325c3337322a5c3235305c3030305c30313761572b5c3332365c3234375c30333648285c3336363f535c33303061565c3030375c3031334f5c3031345c3233355c333731525f5c3334375c3337305c3232305c333033656f6e5c3330315c3234325c323032385c3231305c30333341445c3030335c3030335c303030635c333632555c3033375c3336305c3032315c33353152475c303332435c3033325c3330375c3033325c323034455c3030315554605c3030303a5c303030295c333234565c323037795c3330347c6b5c3336303f5c3337342c5c3137375c3230355e255c3336305c3337322e5c3335335c3231335c32373346365c3334335c3231375c3336355c3331315c3336335c3330375c3332345c303336375c3235325c3334375c3333335c3234363a5c3332375c333434385c3236375c3032365c3335365c3330335c3331325c3336325c32333148565c3333305c3233345c3234315c333731465c3332315c3336325c3336325c323734727b635c3236363e5f5c3333325c3337365c3236355c3330345c3033375c3230315c3333375c3031365a565c3232345c3337305c3030375c3330332646245c3232373a3d5c3237364e715c323336767b5c3031375c333130575c303136235c3031345c333533345c3332335c3236315c3336315c303334415c3330335c323537395c3235315c3031325c3236345c3334365c323433245c3235345c3335365c3236375b5c3235375c3332345c3337345c3230355c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c333132475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c333735784f5c3230315f5c3031355c323432205c3234375c3330335c3337375c3030305c3031335c3234315c3030335c3030305c3235365c3231356e385c3334305c313737735c3333307e425c3230345c3337305c3032355c3336305c333332225c3031327c3f5c3336305c3237325c303230305c3031325c3335305c3332365c3334335c3231365c3030375c3336373d5c3230375c3334342b5c3231375c3335325c3032335c333736635c3334353f5c3332345c5c475c3337345c3337375c3030305f733f215c3334335c3231316339585c333034645c3032305c303131445c3337335c323737746d5f5c3232375c3232355c3334335c3232335c3333335c3033355c3236315c3336325c333735215c3337335c3031305c3337305c3334323f5c3031337c5d7d5c3031325c333432345c3032363a5c3337345c303336495f2c5c3032305c3232375c3032315c3230305c3336315c303230765c3230335c3231342b5c3231345c3337325c3232355c3337365c3335305c3333335c333637427c5c3031325c3337306d5c3032315c3030353e5c3033375c3337305d5c3031305c3033305c303035746b715c3330375c3030335c3337335c3233365c3330335c3336325c3032353e5c3233355c333630635c3334315c3337365c3231377d6f7b615c3334306f5c303136595e5b5c3237325c3331315c3031355c3330355c3237365c3232335c30303472445c3331324156565c3031315c323230465c3332355c3330315c303335303d2b5a58495c3332325c3233325c323337323d5c3031345c3237375c32303471585c303134553c4c6b5c3234375c3331325c3335375c3236335c333235755f355c3234375c3336355c323537525c323732755c3234326d5c3333336b5c3031325c3335355c333036315c3033305c3033305c3330365c3333347e5b5c3032335c3337365c3337315c3033365c3230325c3230355c3332335c3235355c3032336e5c33333368576e315c3231305c3330305c333036365c3334335c3336325c3333305c3237375c3336375c3331305c3336345c303235665c3231325c3336354f5c3332345c3231345c3235355c3137375c3330325c333332575c3231315c3336343b5c3235355c303337525c3236315c3230365c3334374e5c3237315c3236376b5920655c3330305c3336325c3333305c30303054635c3232355c333530315c323134605c32303047415f5c3233335c3033375c3033355c3337375c303030645c3237375c3032327c5c3033365c3332356e5c323537745c333133395c3336355c3235375c3031325c3032335c3237365c303335465c3332365c3032305c3336325b5c323436405c3336325c333436555f5c3232375c3033305c3030305c3237375c333335235c3030345c3032315c333637535c3336345c3336325c3232305c3231345c333237356a5c3032315c3235345c3236353e77385c3331305c3336305c3333315c3330345c3032325c3235335c3234345c3232365c3331357e5c3237355c3332315c3337305c3234305c3232305c3031305c323136447e515c3030345c303032513e5c3335315c3337317e515c3336325c3336325c323734727b635c3236363e545c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3337335c3032355c3235305c3337342e5c3336306e5c3236305c3335345c3336375c3337365c3032335c3332305c333537595c3231364b5c5c695c3332305c333130495c3334335c323336575c3333307e425c323633535c333430575c333033685c323130295c3336305c3337375c3030305c3330325c333530405c3330302b5c3234335b5c323136385c3033375c3333345c3336365c3033375c3232305c3235373d5c333430255c3337345c3333375c3332375c3336355c333735775c3337305c303131702d7b5c3337335c3236355c3332375c3333345c3337375c3030305c3331355c3233375c3232305c3336315c3330345c3236315c3233345c32353462325c3031305c3030345c3234327d5c3333375c323732365c3235375c3331335c3331325c3336315c3331315c3335355c3231365c3333305c333731485c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237375c3235375c3031315c3336302b5c3334315c323634445c3032345c3337305c3137375c3334317420605c3032355c3332315c3235355c3330375c3033345c3031375c3335367b5c3031375c333130505c3233375c3030325c3237365c30333344414f5c3230375c3337365c303237425c3030365c3030315d5c3033325c333334715c3330305c3337365c3334375c3236305c3337345c3230352f5c3235304f5c3337315c3230355c3337365c3234325c3334323f5c3334375c3337325c3337335c3233315c3337315c3031375c3033344b5c3033315c3331325c33303623205c3230304a275c3333355c3337335c3234336a5c3337345c3237345c3235375c3033345c3233365c3333305c3335355c3231375c3232345c323136255c3231345c333435635c3032315c32323040255c3032335c3335365c3337355c3332315c3236357e5e575c3231364f6c765c3330375c3331335c3337325c3336305c3233375c3030325c3237365c30333344414f5c3230375c3337365c303237425c3030365c3030315d5c3033325c333334715c3330305c3337365c3334375c3236305c3337345c3230355c3031315c3336302b5c3334315c323634445c3032345c3337305c3137375c3334317420605c3032355c3332315c3235355c3330375c3033345c3031375c3335367b5c3031375c333130515c3336355c3031315c3337375c303030305c3137375c3235305c3237305c3231375c3337315c3337365c3237365c3334367e435c3330375c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3335325c3237365c30323478457c635c333631275c3330333a275c3232355c3236363b5c333535465c30313026315c323436764659375c3230355c333731465768393c745c3335355c3231375c3232375c333635393e5c3030357c365c3231305c3230325c3233375c3031375c3337342e5c3230345c3031345c3030325c323732355c3237305c3334335c3230315c3337355c333137615c3337315c3031325c3236375c3234335c3337345c3033375c333630275c3230375c3236355c303330355c3031352b5c3330317e5c3033365c3332336f5c333430395c3230365c3335325c3332334b5c3230322963385c3030332a5c3331325c3234305c3231365c3030305c3033347a555c3330335c303035285c33313137235a3c5c3031375a5c303235232a5c3232355c3232335c3231326a5c3335325c333137555c3333305c333531534d5c3236345c323134285b58576e315c3231305c3330375c3033305c3333335c3231375c333133625c3137375c333337235c333230505c323732755c3234326d5c3333336d5c3031325c3335355c333036315c3033305c3033305c3330365c3333347e5b5c3032375c3337365c3337315c3033365c3230325c3235345c3332315e5c3237315c3337325c3335315c3033325b5c3330355c3032375c3232375c323632244f2d76265c3332355c3030336a5c3336315c3330305c3336345c3033345c3031363d5c32303549455c3032345c30303051455c3032345c303030575c3233347c535c3337355c3233377c5c3032315c3336317e266d7b475c323135752d5c32373353555c3236335c3030322b5c3236345c3033305c3330375c3333375c3330375c333134303e5c3335335c3230365c3033365c3333315c323537475c3234325c3232334a4a5c3331355c3033345c3336355c3336305c3336345c323631345c3333352a5c333231525c3231335c3335305c3336353f3e7e205c3137375c3330313e7c555c3334315c333531265c3237315c3336305c3232365c323431675c3334325c303133504948245c3031336d725c3235335c3230315c3230355c3030305c3230325c323134305c32373027703c5c3031345c3031375c3335365c3337345c3335355c3334326f5c3230365c333336255c333630255c3330315c3231375d5c3336305c3335355c3337365c3231325c3334305c3230315c3237327b46455c3334342e5c303032365c333134325c323334605c323230785c3330376c7c5c3237375c3236315c3336345c33313122495c3232345c3235345c3231305c3235365c3234375c323530615c3232315e745c333630307a5c3330355c3333305c3337303c6f5c303035605c3335335c3236372c345c3333353f2d5c3332375c3334335c3235375c3334327e29242b5c3032315c3331305c32313446415c3030305c3232344f5c3237335c3336377e555c333731795e393d5c3236315c3333335c3033372a475c3032325c333036725c3236315c3231305c333130205c3032325c3231315c3336377e5c3335305c3333325c3237372f2b5c333037275c3236363b635c3334355c3337355f5c3337305c3232335c3336305c3232375c3330305c333632683a5c3230355c3337335c3337303b406b5c333537255c3337375c3030305c3332324e5c3233315c3031315c3232335c3231305c3331363e6d5c3237315c3335343f215c3335315f5c3031345c333734475c3336305c3235365c3231335c3234364d5c3235305c3337355c323137485c3236315c3236345c3333315c3031305c3333335c3334345b226d5c3337355c3333355c3330374c5c3031363e5c3334325c3137375c3333372b5c3335302b5c3331345c32353346545c3233345c3232337b2b5c3233375c3030315c323332705c3336354c5c323535373a5c3231325e5c3231305c333630685c333432585c33313656315c3033315c3030345c303032513e5c3335375c3333355c303333575c3334355c333435785c3334345c3336365c3330376c7c5c3237365c3237375c333733247848785c3233335c3334335c3336375c323035625c3032365c3335315c333435595c3331366f5c323435236a5c3337317e526f5d5c3237314f5c3233306e545c303334735c3332335c323436325c3237325c3237365c3032375c3336305c3237365c3231345c3337325c3237344a5c3333324d5c3231315f5c3236346c5c3330315c3236374c6d5c3330355c3330375c3033353a7c5c3231315c3337375c3030307c5c3235375c3234305c3235375c3236367e5c3030315c3337305c3030375c3330335c3033325c3032344f5c3235305c3335315c3237365c3033355c3332325c3236345c3337354040235c303237765c323636515c3330372853245c3230305c3235365c333435507042205c3330375c3337332b5c3335302b5c5c3d5c3030373929375c3234315c3332335c3330335c3337312b5c3330365c3334325c323431515c333137485c3236345c3333325c3236365c3336367b7e5c3030375c3235355c3235365c323335685c323333765c3333325c3330325c323733715c323134465c303036315c3236375c3033375c3232365c3330345c3337375c3030305c323736475c3234305c3234375c333033656f6e5c3330315c3234325c323032385c3231305c30333341445c3030335c3030335c303030635c333632555c3033375c3336305c3032315c33353153515f407e5c333634465c3232365c333631455c3334355c3335345c3231315c3032335c3331335d5c3231315c323635405c3333325c323734703d5c3030375c3030335c323137615251455c3030305c30323451455c3030305c30323451455c3030305c30323451455c3030305c30323451455c3030305c3137375c3337375c333331');
INSERT INTO logo VALUES (99, '\x474946383961325c303030275c3030305c3336375c3232315c3030304343435959592e2e2e5c3231365c3231365c3231365656564646465d5d5d6262625c3331365c3331365c3331365c3031345c3031345c3031345c3234365c3234365c3234365c3234365c3234375c3234375c3337375c3232315c3232315c33373767675c3337375c3333365c3333365c3337375c3334305c3334305c3337375c3230305c3230305c3337375c3236355c3236355c3231355c3231355c3231355757575c3337375c3337365c3337365c33373776765c3337375c3233305c3233305c3337375c3336345c3336345c3337375c3333305c3333305c3337375c3234375c3234375c3337375c3031375c3031375c3337305c3337315c3337315c3337375c3235305c323530635c3030345c3030345c3337375c3335355c3335355c3337375c3233325c3233325c3337375c3237305c3237305c33373740405c3337375c3337355c3337355c3337345c3030305c3030305c33373770705c3337375c3332305c3332305c3331325c3031305c3031305c33373773732020205c33373774745c33373743435c3337375c3337315c3337314a4a4a5c3337372f2f5c3337376e6e5c3337375c3330375c3330375c3337375c3336355c3336355c33373757575c3031305c3031375c3031375c3030365c3031345c3031345c32353064645c3333365c3032365c3032365151515c33373728285c3234375c3234375c3234375c3233345c3233345c3233345c33373762625c3337305c3030365c3030365c3337375c3031315c3031316464645c3334355c3030305c3030305b63633535355c3235355c3237305c3237304949497b54545c3337373d3d5c3033365c3031355c3031355c3337375c3230315c3230315c3337375c3230375c3230376d6d6d5c3337375c3334355c3334355c33373753535c3337372e2e5c3337373c3c5c3337375c3333325c3333325c33373720205c33373722225c3331325c3332315c3332315c3337375c3336335c3336335c3337375c3030325c3030325c3337375c3336305c3336305c3337375c3030345c3030345c3337375c3033305c3033305c33373769695c3337375c3237315c3237315c3337375c3031355c3031353030305c3337375c3334335c3334335c33373759595c3337375c3030355c3030355c3337375c3233375c3233375c3337375c3032345c3032345c3337375c3330345c3330345c3337375c3236325c3236325c3230355c3230355c3230355c3337375b5b235c3030305c3030305c33373739395c3337375c3332325c3332325c3337374c4c5c3337375c3233315c3233315c33373752525c5c5c5c5c5c5c3234365c3236305c3236305c3337375c3033365c3033365c3337375c3032315c3032315c3337375c3032355c3032355c3337375a5a5c3334335c3237335c3237335c3337375c3336315c3336315c3337375c3336325c3336325c33373731315c3337375c3233345c3233345c3336345c3334335c3334335c3337375c3237375c3237375c33353325255c3331345c3030305c3030305c3032375c3032375c3032375c3337377c7c5555555c3231345c3231345c323134685d5d5c33373747475c3033305c3033305c3033305c3336355c5c5c5c2d2d2d5c3337375c3031335c3031335c3337375c3033345c3033345c3337375c3335345c3335347e5c3030305c3030305c33373738385c3334325c3334325c3334325c3337375c3032335c3032335c3337375c3033335c3033335c3230325c3230325c3230325c3333315c3333315c3333315c3337375c3331345c3331343d3d3d5c3337375c3031305c3031305c3337375c3030305c3030305c3030305c3030305c3030305c3337375c3337375c3337375c3337375c3337375c3337375c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c3030305c303030215c3337315c3030345c3030315c3030305c3030305c3232315c3030302c5c3030305c3030305c3030305c303030325c303030275c3030305c3030305c3031305c3337375c303030235c3031315c303334485c3236305c3234305c3330315c3230335c3031305c3032332a5c5c5c3331305c3236305c3234315c3330335c3230375c303230234a5c323234285c323432445c3030365c3032325c3031345c3032345c3230365c3236315c3032315c3234305c3234335c3330375c32313720435c3230325c3332345c323033645c32303340385c3031345c333130385a5c33333140215c3230304730635c3331325c323334495c323633265c32333620745c3331365c3031305a5c3331315c3336335c3230345c33313347285c3031365c3033305c3033304a5c3236345c3235305c3332315c3234335c3030365c303136307a24635c3231305c303335293c5c3033355c323635695c3334305c3334305c3334375c30303448585c3236336a5c3333355c333132355c3335335c323032475c30333576445c3332355c323230225c3031315c3330335c3232375c3030345c3237325c3235325d5c3237335c323030505447665c30333638445c3237335c3236365c3335365c3332363f23785c3336325c3236305c3030305c3232315c3235365d5c3237332e5c3234325c323536795c3032315c3332315c3335375f5c323635465c3234325c33323678235c3332315c3336305c3334315c323535735c3234325c3233325c3334305c3030335c3234355c3336315c3234335c3236345c5c29505c3236305c3337335c3234355c3032315c3331373b457e205c3236305c323134792b5c3231305c303134755c3030375c3333355c3334305c333531635c3331345c3231345c3030335c3234335c3031335f5c3335365c3033325c333432495c3232345c3236353a785c3033365c3234325c333631285c3030316c5c3332325c5c5c3335335c3235343c5c3234325c323236435c3332342e6a7a5c3337375c3232365d3a2b5c3232315c3232355830705c333235525c323035675c303035485f7d5c3330375c3335363b7b6b5c3031345c323336685c3237305c3237325c3333345c3334315c3235315c3030345c3235335c3030325c3334355c3333335c3033373a5c3330367a5c3234315c3032304f305a235c3336305c323234335c3330353c7a5c3334305c5c5c30333738595c3237315c3334345c303032565c3033302d5c3235345c323034485c303233595c3233355c3234375c3033357e5c5c5c3232355c3334315c3330354a79605c3030355c3330314a6c2c5c3234325c3232355c3230315c333133715c3332375c3333345657705c33343148205c303330385c3234305c3230312354445c3236305c3032355c3230355c3335315c3331355c3332355c3233355a5c3032365c3235345c323434425c3033372b7d5c3330305c3032355c3231315c3031305c3235325541545c303230745c30303523735c3137376d5c3236315c3232325c3032356a5c333335685c3334315f2b30215c3330365a3e5c32353277625d5c3033365c333034415c3334347d383e5c3236365c3334345c3230314d3a69235c3232335c3333345d2565573850695c3234345c303337425c3032345c3334305c3334355c323237605c32303629665c3030312c5c3031305c3234305c3234355c323131355c3234355c323531664c50425c323234435c303332595c303130205c3334375c323334745c33323669275c3233355c3230305c3030305c333231435c3231315c3031365c3033315c3236325c3230375c3030345c3030335c3030342a5c3335305c3234305c3230345c3032363a5c3235305c3030345c32313128325c3332315c3234325c323134365c3335325c3335305c3234335c323230462a5c333531415c3030315c3030315c3030303b');


--
-- TOC entry 3242 (class 0 OID 16485)
-- Dependencies: 178
-- Data for Name: motivosdepausa; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO motivosdepausa VALUES ('00', 'PAUSA 10', '00:10:00', false, false);
INSERT INTO motivosdepausa VALUES ('01', 'PAUSA 20', '00:20:00', false, false);
INSERT INTO motivosdepausa VALUES ('02', 'BANHEIRO', '00:05:00', false, false);
INSERT INTO motivosdepausa VALUES ('03', 'MEDICO', '00:30:00', false, false);
INSERT INTO motivosdepausa VALUES ('04', 'REUNIAO', '00:20:00', true, false);
INSERT INTO motivosdepausa VALUES ('05', 'OUTROS', '00:20:00', false, false);


--
-- TOC entry 3243 (class 0 OID 16488)
-- Dependencies: 179
-- Data for Name: rec_middleware; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3320 (class 0 OID 0)
-- Dependencies: 180
-- Name: rec_middleware_serial_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('rec_middleware_serial_seq', 1, false);


--
-- TOC entry 3245 (class 0 OID 16496)
-- Dependencies: 181
-- Data for Name: tb_ag_grupo; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3321 (class 0 OID 0)
-- Dependencies: 182
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_ag_grupo_id_seq', 1, false);


--
-- TOC entry 3247 (class 0 OID 16502)
-- Dependencies: 183
-- Data for Name: tb_agente_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3248 (class 0 OID 16505)
-- Dependencies: 184
-- Data for Name: tb_agente_log_detalhado; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3322 (class 0 OID 0)
-- Dependencies: 185
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('tb_agente_log_detalhado_id_seq', 1, false);


--
-- TOC entry 3323 (class 0 OID 0)
-- Dependencies: 186
-- Name: tb_agente_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_agente_log_id_seq', 1, false);


--
-- TOC entry 3251 (class 0 OID 16512)
-- Dependencies: 187
-- Data for Name: tb_agente_status; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3252 (class 0 OID 16521)
-- Dependencies: 188
-- Data for Name: tb_agentes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3253 (class 0 OID 16525)
-- Dependencies: 189
-- Data for Name: tb_ani; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3254 (class 0 OID 16528)
-- Dependencies: 190
-- Data for Name: tb_ani_route; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3324 (class 0 OID 0)
-- Dependencies: 191
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('tb_ani_route_serial_seq', 1, false);


--
-- TOC entry 3256 (class 0 OID 16534)
-- Dependencies: 192
-- Data for Name: tb_anuncios; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3257 (class 0 OID 16537)
-- Dependencies: 193
-- Data for Name: tb_billing; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3325 (class 0 OID 0)
-- Dependencies: 194
-- Name: tb_billing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_billing_id_seq', 1, false);


--
-- TOC entry 3259 (class 0 OID 16545)
-- Dependencies: 195
-- Data for Name: tb_camp; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3260 (class 0 OID 16550)
-- Dependencies: 196
-- Data for Name: tb_camp_10000; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3326 (class 0 OID 0)
-- Dependencies: 197
-- Name: tb_camp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_camp_id_seq', 10000, false);


--
-- TOC entry 3294 (class 0 OID 16836)
-- Dependencies: 230
-- Data for Name: tb_chamadas; Type: TABLE DATA; Schema: public; Owner: gravador
--



--
-- TOC entry 3262 (class 0 OID 16569)
-- Dependencies: 198
-- Data for Name: tb_codigos; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_codigos VALUES ('2501', 'agent_login');
INSERT INTO tb_codigos VALUES ('2502', 'agent_logout');
INSERT INTO tb_codigos VALUES ('2503', 'agent_avail');
INSERT INTO tb_codigos VALUES ('2504', 'agent_unavail');
INSERT INTO tb_codigos VALUES ('2505', 'agent_pause');


--
-- TOC entry 3263 (class 0 OID 16572)
-- Dependencies: 199
-- Data for Name: tb_dialer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3327 (class 0 OID 0)
-- Dependencies: 200
-- Name: tb_dialer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_dialer_id_seq', 1, false);


--
-- TOC entry 3289 (class 0 OID 16794)
-- Dependencies: 225
-- Data for Name: tb_dialercallback; Type: TABLE DATA; Schema: public; Owner: gravador
--



--
-- TOC entry 3328 (class 0 OID 0)
-- Dependencies: 224
-- Name: tb_dialercallback_camp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('tb_dialercallback_camp_id_seq', 1, false);


--
-- TOC entry 3291 (class 0 OID 16811)
-- Dependencies: 227
-- Data for Name: tb_dialercallback_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3329 (class 0 OID 0)
-- Dependencies: 226
-- Name: tb_dialercallback_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_dialercallback_log_id_seq', 1, false);


--
-- TOC entry 3293 (class 0 OID 16821)
-- Dependencies: 229
-- Data for Name: tb_dialercallback_num; Type: TABLE DATA; Schema: public; Owner: gravador
--



--
-- TOC entry 3330 (class 0 OID 0)
-- Dependencies: 228
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('tb_dialercallback_num_id_seq', 1, false);


--
-- TOC entry 3265 (class 0 OID 16578)
-- Dependencies: 201
-- Data for Name: tb_dnis; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3266 (class 0 OID 16581)
-- Dependencies: 202
-- Data for Name: tb_dt_chamadas; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3267 (class 0 OID 16587)
-- Dependencies: 203
-- Data for Name: tb_facilidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_facilidades VALUES ('LOGIN', 'agent_login', 1);
INSERT INTO tb_facilidades VALUES ('LOGOUT', 'agent_logout', 1);
INSERT INTO tb_facilidades VALUES ('NÃO DISPONIVEL', 'agent_unavail', 1);
INSERT INTO tb_facilidades VALUES ('DISPONIVEL', 'agent_avail', 1);
INSERT INTO tb_facilidades VALUES ('PAUSA', 'agent_pause', 1);


--
-- TOC entry 3296 (class 0 OID 16925)
-- Dependencies: 232
-- Data for Name: tb_internalchat; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3331 (class 0 OID 0)
-- Dependencies: 231
-- Name: tb_internalchat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('tb_internalchat_id_seq', 1, false);


--
-- TOC entry 3268 (class 0 OID 16590)
-- Dependencies: 204
-- Data for Name: tb_interval_rel; Type: TABLE DATA; Schema: public; Owner: callproadmin
--

INSERT INTO tb_interval_rel VALUES ('00:00:00');
INSERT INTO tb_interval_rel VALUES ('00:30:00');
INSERT INTO tb_interval_rel VALUES ('01:00:00');
INSERT INTO tb_interval_rel VALUES ('02:00:00');
INSERT INTO tb_interval_rel VALUES ('03:00:00');
INSERT INTO tb_interval_rel VALUES ('04:00:00');
INSERT INTO tb_interval_rel VALUES ('05:00:00');
INSERT INTO tb_interval_rel VALUES ('06:00:00');
INSERT INTO tb_interval_rel VALUES ('07:00:00');
INSERT INTO tb_interval_rel VALUES ('08:00:00');
INSERT INTO tb_interval_rel VALUES ('09:00:00');
INSERT INTO tb_interval_rel VALUES ('10:00:00');
INSERT INTO tb_interval_rel VALUES ('11:00:00');
INSERT INTO tb_interval_rel VALUES ('12:00:00');
INSERT INTO tb_interval_rel VALUES ('13:00:00');
INSERT INTO tb_interval_rel VALUES ('14:00:00');
INSERT INTO tb_interval_rel VALUES ('15:00:00');
INSERT INTO tb_interval_rel VALUES ('16:00:00');
INSERT INTO tb_interval_rel VALUES ('17:00:00');
INSERT INTO tb_interval_rel VALUES ('18:00:00');
INSERT INTO tb_interval_rel VALUES ('19:00:00');
INSERT INTO tb_interval_rel VALUES ('20:00:00');
INSERT INTO tb_interval_rel VALUES ('21:00:00');
INSERT INTO tb_interval_rel VALUES ('22:00:00');
INSERT INTO tb_interval_rel VALUES ('23:00:00');
INSERT INTO tb_interval_rel VALUES ('01:30:00');
INSERT INTO tb_interval_rel VALUES ('02:30:00');
INSERT INTO tb_interval_rel VALUES ('03:30:00');
INSERT INTO tb_interval_rel VALUES ('04:30:00');
INSERT INTO tb_interval_rel VALUES ('05:30:00');
INSERT INTO tb_interval_rel VALUES ('06:30:00');
INSERT INTO tb_interval_rel VALUES ('07:30:00');
INSERT INTO tb_interval_rel VALUES ('08:30:00');
INSERT INTO tb_interval_rel VALUES ('09:30:00');
INSERT INTO tb_interval_rel VALUES ('10:30:00');
INSERT INTO tb_interval_rel VALUES ('11:30:00');
INSERT INTO tb_interval_rel VALUES ('12:30:00');
INSERT INTO tb_interval_rel VALUES ('13:30:00');
INSERT INTO tb_interval_rel VALUES ('14:30:00');
INSERT INTO tb_interval_rel VALUES ('15:30:00');
INSERT INTO tb_interval_rel VALUES ('16:30:00');
INSERT INTO tb_interval_rel VALUES ('17:30:00');
INSERT INTO tb_interval_rel VALUES ('18:30:00');
INSERT INTO tb_interval_rel VALUES ('19:30:00');
INSERT INTO tb_interval_rel VALUES ('20:30:00');
INSERT INTO tb_interval_rel VALUES ('21:30:00');
INSERT INTO tb_interval_rel VALUES ('22:30:00');
INSERT INTO tb_interval_rel VALUES ('23:30:00');


--
-- TOC entry 3269 (class 0 OID 16593)
-- Dependencies: 205
-- Data for Name: tb_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3270 (class 0 OID 16601)
-- Dependencies: 206
-- Data for Name: tb_musiconhold; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3271 (class 0 OID 16604)
-- Dependencies: 207
-- Data for Name: tb_queues; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_queues VALUES ('Atendimento', 'record#;ck_ag_log#;playmusiconhold#Default;');


--
-- TOC entry 3272 (class 0 OID 16610)
-- Dependencies: 208
-- Data for Name: tb_ramais; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_ramais VALUES (0, 'SIP', '2000', 0, 0);


--
-- TOC entry 3332 (class 0 OID 0)
-- Dependencies: 209
-- Name: tb_ramais_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tb_ramais_id_seq', 1, false);


--
-- TOC entry 3281 (class 0 OID 16640)
-- Dependencies: 217
-- Data for Name: tb_rel_ani; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3274 (class 0 OID 16615)
-- Dependencies: 210
-- Data for Name: tb_rel_virtual_group; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3275 (class 0 OID 16618)
-- Dependencies: 211
-- Data for Name: tb_sms_conf_alerta; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3276 (class 0 OID 16621)
-- Dependencies: 212
-- Data for Name: tb_sms_received; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3333 (class 0 OID 0)
-- Dependencies: 213
-- Name: tb_sms_received_id_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('tb_sms_received_id_seq', 1, false);


--
-- TOC entry 3278 (class 0 OID 16627)
-- Dependencies: 214
-- Data for Name: tb_sms_send; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3334 (class 0 OID 0)
-- Dependencies: 215
-- Name: tb_sms_send_id_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('tb_sms_send_id_seq', 1, false);


--
-- TOC entry 3280 (class 0 OID 16634)
-- Dependencies: 216
-- Data for Name: tb_tabs; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3283 (class 0 OID 16649)
-- Dependencies: 219
-- Data for Name: tb_time_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3284 (class 0 OID 16655)
-- Dependencies: 220
-- Data for Name: tb_trunks; Type: TABLE DATA; Schema: public; Owner: callproadmin
--

INSERT INTO tb_trunks VALUES ('0%', NULL, NULL);


--
-- TOC entry 3282 (class 0 OID 16643)
-- Dependencies: 218
-- Data for Name: tb_uf; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tb_uf VALUES ('11%', 'São Paulo');
INSERT INTO tb_uf VALUES ('12%', 'São Paulo');
INSERT INTO tb_uf VALUES ('13%', 'São Paulo');
INSERT INTO tb_uf VALUES ('14%', 'São Paulo');
INSERT INTO tb_uf VALUES ('15%', 'São Paulo');
INSERT INTO tb_uf VALUES ('16%', 'São Paulo');
INSERT INTO tb_uf VALUES ('17%', 'São Paulo');
INSERT INTO tb_uf VALUES ('18%', 'São Paulo');
INSERT INTO tb_uf VALUES ('19%', 'São Paulo');
INSERT INTO tb_uf VALUES ('22%', 'Rio de Janeiro');
INSERT INTO tb_uf VALUES ('21%', 'Rio de Janeiro');
INSERT INTO tb_uf VALUES ('24%', 'Rio de Janeiro');
INSERT INTO tb_uf VALUES ('28%', 'Espírito Santo');
INSERT INTO tb_uf VALUES ('31%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('32%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('33%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('34%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('35%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('37%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('38%', 'Minas Gerais');
INSERT INTO tb_uf VALUES ('41%', 'Paraná');
INSERT INTO tb_uf VALUES ('42%', 'Paraná');
INSERT INTO tb_uf VALUES ('43%', 'Paraná');
INSERT INTO tb_uf VALUES ('44%', 'Paraná');
INSERT INTO tb_uf VALUES ('45%', 'Paraná');
INSERT INTO tb_uf VALUES ('46%', 'Paraná');
INSERT INTO tb_uf VALUES ('47%', 'Santa Catarina');
INSERT INTO tb_uf VALUES ('48%', 'Santa Catarina');
INSERT INTO tb_uf VALUES ('49%', 'Santa Catarina');
INSERT INTO tb_uf VALUES ('51%', 'Rio Grande do Sul');
INSERT INTO tb_uf VALUES ('53%', 'Rio Grande do Sul');
INSERT INTO tb_uf VALUES ('54%', 'Rio Grande do Sul');
INSERT INTO tb_uf VALUES ('55%', 'Rio Grande do Sul');
INSERT INTO tb_uf VALUES ('61%', 'Distrito Federal e Goiás');
INSERT INTO tb_uf VALUES ('62%', 'Goiás');
INSERT INTO tb_uf VALUES ('63%', 'Tocantins');
INSERT INTO tb_uf VALUES ('64%', 'Goiás');
INSERT INTO tb_uf VALUES ('65%', 'Mato Grosso');
INSERT INTO tb_uf VALUES ('66%', 'Mato Grosso ');
INSERT INTO tb_uf VALUES ('67%', 'Mato Grosso do Sul');
INSERT INTO tb_uf VALUES ('68%', 'Acre');
INSERT INTO tb_uf VALUES ('69%', 'Rondônia');
INSERT INTO tb_uf VALUES ('71%', 'Bahia');
INSERT INTO tb_uf VALUES ('73%', 'Bahia');
INSERT INTO tb_uf VALUES ('74%', 'Bahia');
INSERT INTO tb_uf VALUES ('75%', 'Bahia');
INSERT INTO tb_uf VALUES ('77%', 'Bahia');
INSERT INTO tb_uf VALUES ('79%', 'Sergipe');
INSERT INTO tb_uf VALUES ('81%', 'Pernambuco');
INSERT INTO tb_uf VALUES ('82%', 'Alagoas');
INSERT INTO tb_uf VALUES ('83%', 'Paraíba');
INSERT INTO tb_uf VALUES ('84%', 'Rio Grande do Norte');
INSERT INTO tb_uf VALUES ('85%', 'Ceará');
INSERT INTO tb_uf VALUES ('87%', 'Pernambuco ');
INSERT INTO tb_uf VALUES ('88%', 'Ceará ');
INSERT INTO tb_uf VALUES ('89%', 'Piauí ');
INSERT INTO tb_uf VALUES ('92%', 'Amazonas ');
INSERT INTO tb_uf VALUES ('98%', 'Maranhão ');
INSERT INTO tb_uf VALUES ('99%', 'Maranhão');
INSERT INTO tb_uf VALUES ('27%', 'Espírito Santo');
INSERT INTO tb_uf VALUES ('86%', 'Piauí');
INSERT INTO tb_uf VALUES ('91%', 'Pará');
INSERT INTO tb_uf VALUES ('93%', 'Pará');
INSERT INTO tb_uf VALUES ('94%', 'Pará');
INSERT INTO tb_uf VALUES ('95%', 'Roraima');
INSERT INTO tb_uf VALUES ('96%', 'Amapá');
INSERT INTO tb_uf VALUES ('97%', 'Amazonas');


--
-- TOC entry 3285 (class 0 OID 16658)
-- Dependencies: 221
-- Data for Name: tb_virtual_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3286 (class 0 OID 16670)
-- Dependencies: 222
-- Data for Name: tbl; Type: TABLE DATA; Schema: public; Owner: callproadmin
--



--
-- TOC entry 3287 (class 0 OID 16673)
-- Dependencies: 223
-- Data for Name: td_dias_esp; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3048 (class 2606 OID 16689)
-- Name: infos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY infos
    ADD CONSTRAINT infos_pkey PRIMARY KEY (tipo);


--
-- TOC entry 3050 (class 2606 OID 16691)
-- Name: login_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY login
    ADD CONSTRAINT login_pkey PRIMARY KEY ("user");


--
-- TOC entry 3052 (class 2606 OID 16693)
-- Name: logo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY logo
    ADD CONSTRAINT logo_pkey PRIMARY KEY (id);


--
-- TOC entry 3054 (class 2606 OID 16695)
-- Name: motivosdepausa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY motivosdepausa
    ADD CONSTRAINT motivosdepausa_pkey PRIMARY KEY (id);


--
-- TOC entry 3056 (class 2606 OID 16697)
-- Name: rec_middleware_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rec_middleware
    ADD CONSTRAINT rec_middleware_pkey PRIMARY KEY (serial);


--
-- TOC entry 3058 (class 2606 OID 16699)
-- Name: tb_ag_grupo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_pkey PRIMARY KEY (id);


--
-- TOC entry 3062 (class 2606 OID 16873)
-- Name: tb_agente_log_detalhado_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_agente_log_detalhado
    ADD CONSTRAINT tb_agente_log_detalhado_pkey PRIMARY KEY (id);


--
-- TOC entry 3060 (class 2606 OID 16862)
-- Name: tb_agente_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_agente_log
    ADD CONSTRAINT tb_agente_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3064 (class 2606 OID 16883)
-- Name: tb_agente_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_agente_status
    ADD CONSTRAINT tb_agente_status_pkey PRIMARY KEY (id);


--
-- TOC entry 3066 (class 2606 OID 16892)
-- Name: tb_agentes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_agentes
    ADD CONSTRAINT tb_agentes_pkey PRIMARY KEY (id);


--
-- TOC entry 3068 (class 2606 OID 16709)
-- Name: tb_ani_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_ani
    ADD CONSTRAINT tb_ani_pkey PRIMARY KEY (nome);


--
-- TOC entry 3070 (class 2606 OID 16711)
-- Name: tb_ani_route_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_ani_route
    ADD CONSTRAINT tb_ani_route_pkey PRIMARY KEY (serial);


--
-- TOC entry 3075 (class 2606 OID 16713)
-- Name: tb_billing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_billing
    ADD CONSTRAINT tb_billing_pkey PRIMARY KEY (id);


--
-- TOC entry 3079 (class 2606 OID 16715)
-- Name: tb_camp_10000_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_camp_10000
    ADD CONSTRAINT tb_camp_10000_pkey PRIMARY KEY (tel);


--
-- TOC entry 3077 (class 2606 OID 16717)
-- Name: tb_camp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_camp
    ADD CONSTRAINT tb_camp_pkey PRIMARY KEY (id);


--
-- TOC entry 3124 (class 2606 OID 16849)
-- Name: tb_chamadas_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY tb_chamadas
    ADD CONSTRAINT tb_chamadas_pkey PRIMARY KEY (uniqueid);


--
-- TOC entry 3081 (class 2606 OID 16721)
-- Name: tb_codigos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_codigos
    ADD CONSTRAINT tb_codigos_pkey PRIMARY KEY (codigo);


--
-- TOC entry 3120 (class 2606 OID 16818)
-- Name: tb_dialercallback_log_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_dialercallback_log
    ADD CONSTRAINT tb_dialercallback_log_pk PRIMARY KEY (id);


--
-- TOC entry 3122 (class 2606 OID 16835)
-- Name: tb_dialercallback_num_pk; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY tb_dialercallback_num
    ADD CONSTRAINT tb_dialercallback_num_pk PRIMARY KEY (id);


--
-- TOC entry 3118 (class 2606 OID 16808)
-- Name: tb_dialercallback_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY tb_dialercallback
    ADD CONSTRAINT tb_dialercallback_pkey PRIMARY KEY (camp_id);


--
-- TOC entry 3083 (class 2606 OID 16723)
-- Name: tb_dnis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_dnis
    ADD CONSTRAINT tb_dnis_pkey PRIMARY KEY (dnis);


--
-- TOC entry 3085 (class 2606 OID 16725)
-- Name: tb_dt_chamadas_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_dt_chamadas
    ADD CONSTRAINT tb_dt_chamadas_pkey PRIMARY KEY (uniqueid);


--
-- TOC entry 3087 (class 2606 OID 16727)
-- Name: tb_facilidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_facilidades
    ADD CONSTRAINT tb_facilidades_pkey PRIMARY KEY (recurso);


--
-- TOC entry 3126 (class 2606 OID 16935)
-- Name: tb_internalchat_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_internalchat
    ADD CONSTRAINT tb_internalchat_pkey PRIMARY KEY (id);


--
-- TOC entry 3089 (class 2606 OID 16729)
-- Name: tb_interval_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_interval_rel
    ADD CONSTRAINT tb_interval_rel_pkey PRIMARY KEY (intervalo);


--
-- TOC entry 3091 (class 2606 OID 16731)
-- Name: tb_musiconhold_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_musiconhold
    ADD CONSTRAINT tb_musiconhold_pkey PRIMARY KEY (classe);


--
-- TOC entry 3093 (class 2606 OID 16733)
-- Name: tb_queues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_queues
    ADD CONSTRAINT tb_queues_pkey PRIMARY KEY (name);


--
-- TOC entry 3095 (class 2606 OID 16735)
-- Name: tb_ramais_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ramais
    ADD CONSTRAINT tb_ramais_pkey PRIMARY KEY (id);


--
-- TOC entry 3097 (class 2606 OID 16737)
-- Name: tb_rel_virtual_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_rel_virtual_group
    ADD CONSTRAINT tb_rel_virtual_group_pkey PRIMARY KEY (grupo);


--
-- TOC entry 3099 (class 2606 OID 16739)
-- Name: tb_sms_conf_alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_sms_conf_alerta
    ADD CONSTRAINT tb_sms_conf_alerta_pkey PRIMARY KEY (numero);


--
-- TOC entry 3101 (class 2606 OID 16741)
-- Name: tb_sms_received_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_sms_received
    ADD CONSTRAINT tb_sms_received_pkey PRIMARY KEY (id);


--
-- TOC entry 3103 (class 2606 OID 16743)
-- Name: tb_sms_send_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_sms_send
    ADD CONSTRAINT tb_sms_send_pkey PRIMARY KEY (id);


--
-- TOC entry 3105 (class 2606 OID 16745)
-- Name: tb_tabs_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_tabs
    ADD CONSTRAINT tb_tabs_pkey PRIMARY KEY (tab);


--
-- TOC entry 3110 (class 2606 OID 16747)
-- Name: tb_time_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_time_conditions
    ADD CONSTRAINT tb_time_conditions_pkey PRIMARY KEY (name);


--
-- TOC entry 3112 (class 2606 OID 16749)
-- Name: tb_trunks_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_trunks
    ADD CONSTRAINT tb_trunks_pkey PRIMARY KEY (tronco);


--
-- TOC entry 3108 (class 2606 OID 16647)
-- Name: tb_uf_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_uf
    ADD CONSTRAINT tb_uf_pkey PRIMARY KEY (num);


--
-- TOC entry 3114 (class 2606 OID 16751)
-- Name: tb_virtual_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_virtual_groups
    ADD CONSTRAINT tb_virtual_groups_pkey PRIMARY KEY (virtual_group);


--
-- TOC entry 3116 (class 2606 OID 16753)
-- Name: td_dias_esp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY td_dias_esp
    ADD CONSTRAINT td_dias_esp_pkey PRIMARY KEY (date);


--
-- TOC entry 3071 (class 1259 OID 16755)
-- Name: idx_databil; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_databil ON public.tb_billing USING btree (data_sistema);


--
-- TOC entry 3072 (class 1259 OID 16756)
-- Name: idx_grp_bil; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grp_bil ON public.tb_billing USING btree (grupo);


--
-- TOC entry 3073 (class 1259 OID 16757)
-- Name: idx_hora_bil; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_hora_bil ON public.tb_billing USING btree (hora_sistema);


--
-- TOC entry 3106 (class 1259 OID 16648)
-- Name: idx_rel_ani_grp; Type: INDEX; Schema: public; Owner: callproadmin
--

CREATE INDEX idx_rel_ani_grp ON public.tb_rel_ani USING btree (num);


--
-- TOC entry 3129 (class 2606 OID 16765)
-- Name: ani; Type: FK CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY tb_ani_route
    ADD CONSTRAINT ani FOREIGN KEY (ani) REFERENCES tb_ani(nome);


--
-- TOC entry 3128 (class 2606 OID 16909)
-- Name: tb_ag_grupo_agente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_agente_fkey FOREIGN KEY (agente) REFERENCES tb_agentes(id);


--
-- TOC entry 3127 (class 2606 OID 16775)
-- Name: tb_ag_grupo_virtual_grp_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_virtual_grp_fkey FOREIGN KEY (virtual_grp) REFERENCES tb_virtual_groups(virtual_group);


--
-- TOC entry 3303 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2020-09-09 20:30:35

--
-- PostgreSQL database dump complete
--

