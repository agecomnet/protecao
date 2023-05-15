--
-- PostgreSQL database dump
--

-- Dumped from database version 13.9
-- Dumped by pg_dump version 15.2

-- Started on 2023-04-20 15:10:28

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
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 730 (class 1247 OID 3638698)
-- Name: nserv_result; Type: TYPE; Schema: public; Owner: gravador
--

CREATE TYPE public.nserv_result AS
(
	atendidas bigint,
	natendidas bigint,
	o_serv double precision,
	o_fila double precision,
	o_atendida bigint,
	i_fila double precision,
	tot_chamadas double precision,
	tp_n_serv character varying,
	datenow timestamp with time zone,
	chamadas_out bigint
);


ALTER TYPE public.nserv_result OWNER TO gravador;

--
-- TOC entry 293 (class 1255 OID 3638699)
-- Name: fn_get_oc_last_message(character varying, character varying); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_last_message(_src character varying, _dst character varying) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
DECLARE _last timestamp;
BEGIN
_last = (select max(date) from tb_whatapp_inbound where date > now() - interval '1 day' and dst = _dst and src = _src
union
select max(date) from tb_whatapp_outbound  where date > now() - interval '1 day' and  dst = _dst and src = _src
order by max desc limit 1);
RETURN _last;
END;
$$;


ALTER FUNCTION public.fn_get_oc_last_message(_src character varying, _dst character varying) OWNER TO gravador;

--
-- TOC entry 294 (class 1255 OID 3638700)
-- Name: fn_get_oc_protocol(); Type: FUNCTION; Schema: public; Owner: callproadmin
--

CREATE FUNCTION public.fn_get_oc_protocol() RETURNS bigint
    LANGUAGE sql
    AS $$ (select (to_char(now(), 'YYYYMMDD') || to_char((((SELECT count(protocol) FROM public.tb_oc_tickets where protocol > (to_char(now(), 'YYYYMMDD00000'))::bigint)) + ((SELECT count(protocol) FROM public.tb_chamadas where date_start > now()::date and protocol > (to_char(now(), 'YYYYMMDD00000'))::bigint)) + 1), 'FM09999'))::bigint); $$;


ALTER FUNCTION public.fn_get_oc_protocol() OWNER TO callproadmin;

--
-- TOC entry 295 (class 1255 OID 3638701)
-- Name: fn_get_oc_protocol(bigint); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocol(_protocol bigint) RETURNS json
    LANGUAGE sql
    AS $$ select json_agg(a) as protocol from(select tb_oc_tickets.id, protocol , virtualgroup, oc_contact_id, displayname, channel, src, dst, assignedby, date_start, acd_start, agente_start, agente_end, date_end, status,(select nickname from tb_agentes where id = assignedby) as agente, (select count(*) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as inbound,(select min(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as mininbound,(select max(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as maxinbound,(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as outbound,(select min(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as minoutbound,(select max(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as maxoutbound,(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol and agente=assignedby) as ag_outbound from tb_oc_tickets left join tb_oc_contact on tb_oc_contact.id = oc_contact_id where protocol= _protocol order by protocol)a; $$;


ALTER FUNCTION public.fn_get_oc_protocol(_protocol bigint) OWNER TO gravador;

--
-- TOC entry 296 (class 1255 OID 3638702)
-- Name: fn_get_oc_protocol(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocol(prefix text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
BEGIN
select (to_char(now(), 'YYYYMMDD') || to_char((
 SELECT count(protocol) + 1 FROM public.tb_oc_tickets where 
protocol > (to_char(now(), 'YYYYMMDD00000'))::bigint
 ), 'FM09999'))::bigint;
end;
$$;


ALTER FUNCTION public.fn_get_oc_protocol(prefix text) OWNER TO gravador;

--
-- TOC entry 297 (class 1255 OID 3638703)
-- Name: fn_get_oc_protocol1(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocol1(prefix text) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $_$
select ($1 || to_char(now(), 'YYYYMMDD') || to_char((
	SELECT count(protocol) + 1	FROM public.tb_oc_tickets where 
protocol > ($1 || to_char(now(), 'YYYYMMDD00000'))::bigint
	), 'FM09999'))::bigint;
$_$;


ALTER FUNCTION public.fn_get_oc_protocol1(prefix text) OWNER TO gravador;

--
-- TOC entry 298 (class 1255 OID 3638704)
-- Name: fn_get_oc_protocols(date, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocols(_date date, _src text) RETURNS json
    LANGUAGE sql
    AS $$
select json_agg(a) as protocol from (
select tb_oc_tickets.id,protocol ,virtualgroup,oc_contact_id,displayname,channel,src,dst,assignedby,date_start,acd_start,agente_start,agente_end,date_end,status,
(select nickname from tb_agentes where id = assignedby) as agente,	
(select count(*) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as inbound,
(select min(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as mininbound,
(select max(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as maxinbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as outbound,
(select min(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as minoutbound,
(select max(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as maxoutbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol and agente=assignedby) as ag_outbound
from tb_oc_tickets left join tb_oc_contact on tb_oc_contact.id = oc_contact_id where (date_start::date = _date or status < 9) order by protocol)a;

$$;


ALTER FUNCTION public.fn_get_oc_protocols(_date date, _src text) OWNER TO gravador;

--
-- TOC entry 299 (class 1255 OID 3638705)
-- Name: fn_get_oc_protocols(date, text, integer); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocols(_date date, _src text, _level integer) RETURNS json
    LANGUAGE sql
    AS $$
select json_agg(a) as protocol from (
select tb_oc_tickets.id,protocol ,oc_contact_id,displayname,channel,src,dst,assignedby,date_start,acd_start,agente_start,agente_end,date_end,status,
(select nickname from tb_agentes where id = assignedby) as agente,	
(select count(*) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as inbound,
(select min(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as mininbound,
(select max(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as maxinbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as outbound,
(select min(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as minoutbound,
(select max(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as maxoutbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol and agente=assignedby) as ag_outbound
from tb_oc_tickets left join tb_oc_contact on tb_oc_contact.id = oc_contact_id where date_start::date = _date and status <= _level and src=_src order by protocol)a;
$$;


ALTER FUNCTION public.fn_get_oc_protocols(_date date, _src text, _level integer) OWNER TO gravador;

--
-- TOC entry 300 (class 1255 OID 3638706)
-- Name: fn_get_oc_protocols_agente(date, date, bigint); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocols_agente(_date_ini date, _date_end date, _agente bigint) RETURNS json
    LANGUAGE sql
    AS $$
select json_agg(a) as protocol from (
select tb_oc_tickets.id,protocol ,oc_contact_id,displayname,channel,src,dst,assignedby,date_start,acd_start,agente_start,agente_end,date_end,status,
(select nickname from tb_agentes where id = assignedby) as agente,	
(select count(*) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as inbound,
(select min(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as mininbound,
(select max(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as maxinbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as outbound,
(select min(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as minoutbound,
(select max(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as maxoutbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol and agente=assignedby) as ag_outbound
from tb_oc_tickets left join tb_oc_contact on tb_oc_contact.id = oc_contact_id where date_start between _date_ini and _date_end and assignedby=_agente order by protocol)a;
$$;


ALTER FUNCTION public.fn_get_oc_protocols_agente(_date_ini date, _date_end date, _agente bigint) OWNER TO gravador;

--
-- TOC entry 301 (class 1255 OID 3638707)
-- Name: fn_get_oc_protocols_agente(timestamp without time zone, timestamp without time zone, bigint); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_get_oc_protocols_agente(_date_ini timestamp without time zone, _date_end timestamp without time zone, _agente bigint) RETURNS json
    LANGUAGE sql
    AS $$
select json_agg(a) as protocol from (
select tb_oc_tickets.id,protocol ,oc_contact_id,displayname,channel,src,dst,assignedby,date_start,acd_start,agente_start,agente_end,date_end,status,
(select nickname from tb_agentes where id = assignedby) as agente,	
(select count(*) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as inbound,
(select min(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as mininbound,
(select max(date) from tb_whatapp_inbound where protocol = tb_oc_tickets.protocol) as maxinbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as outbound,
(select min(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as minoutbound,
(select max(date) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol) as maxoutbound,
(select count(*) from tb_whatapp_outbound where protocol = tb_oc_tickets.protocol and agente=assignedby) as ag_outbound
from tb_oc_tickets left join tb_oc_contact on tb_oc_contact.id = oc_contact_id where ((status > 8 and date_start between _date_ini and _date_end) or status between 2 and 8) and assignedby=_agente order by protocol)a;
$$;


ALTER FUNCTION public.fn_get_oc_protocols_agente(_date_ini timestamp without time zone, _date_end timestamp without time zone, _agente bigint) OWNER TO gravador;

--
-- TOC entry 302 (class 1255 OID 3638708)
-- Name: fn_insert_new_oc_message(character varying, character varying, integer, integer, character varying, text, character varying, integer, character varying, character varying, character varying, text, date, timestamp without time zone, character varying, timestamp without time zone, timestamp without time zone, character varying, uuid, boolean); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_insert_new_oc_message(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$

DECLARE _protocol bigint;
DECLARE _id_contact integer;
BEGIN
PERFORM  insert_contact_whatsapp(REPLACE($11,'whatsapp:',''));
_id_contact = (select id_contact from tb_oc_contact_connections where connection = REPLACE($11,'whatsapp:','') limit 1);
IF (SELECT count(*) FROM public.tb_oc_tickets where date_end is null and dst = REPLACE($11,'whatsapp:','')) > 0 THEN
	_protocol = (SELECT protocol FROM public.tb_oc_tickets where date_end is null and dst = REPLACE($11,'whatsapp:','') order by date_start desc limit 1);
ELSE
    _protocol = (select (to_char(now(), 'YYYYMMDD') || to_char((
 SELECT count(protocol) + 1 FROM public.tb_oc_tickets where 
protocol > (to_char(now(), 'YYYYMMDD00000'))::bigint
 ), 'FM09999'))::bigint);
	INSERT INTO public.tb_oc_tickets(protocol, protocol_src, oc_contact_id, channel, src, dst,status) VALUES (_protocol, _protocol, _id_contact, 'whatsapp', $7, REPLACE($11,'whatsapp:',''), 0);
END IF;
INSERT INTO public.tb_whatapp_inbound(mediacontenttype, smsmessagesid, nummedia, smsstatus, smssid, body, src, numsegments, messagesid,
 accountsid, dst, mediaurl, apiversion, date, errorcode, datesent, dateupdate, errormessage, ticket_id, coletado,protocol) 
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,_protocol);
	if (select count(*) from tb_whatapp_outbound  where protocol = _protocol) = 0 THEN
		if (select
case when (select count(*) from td_dias_esp where "date" = now()::date)  = 1 then false else
case when extract(dow from now()) between 1 and 5
then case when now()::time between '08:00:00' and '17:45:00' then true else false end else false end end) = true THEN
		INSERT INTO public.tb_whatapp_outbound (smsstatus, body, src, dst,protocol)
		(select 0,REPLACE(msg,'{PROTOCOL}',_protocol::text),$7,$11,_protocol from tb_oc_messages where src = $7 and type < 101 order by type);
		else
			INSERT INTO public.tb_whatapp_outbound (smsstatus, body, src, dst,protocol)
		(select 0,REPLACE(msg,'{PROTOCOL}',_protocol::text),$7,$11,_protocol from tb_oc_messages where src = $7 and type > 100 order by type);
		END IF;
	else
		update tb_oc_tickets set status = 1, acd_start = now(), virtualgroup='COMERCIAL' where protocol = _protocol and status < 2;
	END IF;
RETURN _protocol;
END;
$_$;


ALTER FUNCTION public.fn_insert_new_oc_message(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean) OWNER TO gravador;

--
-- TOC entry 303 (class 1255 OID 3638709)
-- Name: fn_insert_new_oc_message_ivr(character varying, character varying, integer, integer, character varying, text, character varying, integer, character varying, character varying, character varying, text, date, timestamp without time zone, character varying, timestamp without time zone, timestamp without time zone, character varying, uuid, boolean); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_insert_new_oc_message_ivr(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean) RETURNS text
    LANGUAGE plpgsql
    AS $_$
 DECLARE _protocol bigint; DECLARE _status int; DECLARE _id_contact integer; DECLARE _assignedby text = '0'; BEGIN PERFORM insert_contact_whatsapp(REPLACE($11,'whatsapp:','')); _id_contact = (select id_contact from tb_oc_contact_connections where connection = REPLACE($11,'whatsapp:','') limit 1); IF (SELECT count(*) FROM public.tb_oc_tickets where date_end is null and src = $7 and dst = REPLACE($11,'whatsapp:','')) > 0 THEN _protocol = (SELECT protocol FROM public.tb_oc_tickets where date_end is null and src = $7 and dst = REPLACE($11,'whatsapp:','') order by date_start desc limit 1); _status = (SELECT status FROM public.tb_oc_tickets where protocol = _protocol); _assignedby = (SELECT assignedby FROM public.tb_oc_tickets where protocol = _protocol and status > 1)::text; if _assignedby is null then _assignedby = '0'; END IF; ELSE _status = 0; _protocol = (select public.fn_get_oc_protocol()); INSERT INTO public.tb_oc_tickets(protocol, protocol_src, oc_contact_id, channel, src, dst,status) VALUES (_protocol, _protocol, _id_contact, 'whatsapp', $7, REPLACE($11,'whatsapp:',''), 0); END IF; INSERT INTO public.tb_whatapp_inbound(mediacontenttype, smsmessagesid, nummedia, smsstatus, smssid, body, src, numsegments, messagesid, accountsid, dst, mediaurl, apiversion, date, errorcode, datesent, dateupdate, errormessage, ticket_id, coletado,protocol) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,_protocol); RETURN _protocol::text || '|' || _status::text || '|' || _assignedby; END; 
$_$;


ALTER FUNCTION public.fn_insert_new_oc_message_ivr(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean) OWNER TO gravador;

--
-- TOC entry 304 (class 1255 OID 3638710)
-- Name: fn_insert_new_oc_message_ivr(character varying, character varying, integer, integer, character varying, text, character varying, integer, character varying, character varying, character varying, text, date, timestamp without time zone, character varying, timestamp without time zone, timestamp without time zone, character varying, uuid, boolean, text, text, text, boolean, smallint); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_insert_new_oc_message_ivr(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean, _profilename text, _notifyname text, _author text, _isforwarded boolean, _forwardingscore smallint) RETURNS text
    LANGUAGE plpgsql
    AS $_$
 DECLARE _protocol bigint; DECLARE _status int; DECLARE _id_contact integer; DECLARE _assignedby text = '0'; BEGIN PERFORM insert_contact_whatsapp(REPLACE($11,'whatsapp:',''),_profilename); _id_contact = (select id_contact from tb_oc_contact_connections where connection = REPLACE($11,'whatsapp:','') limit 1); IF (SELECT count(*) FROM public.tb_oc_tickets where date_end is null and src = $7 and dst = REPLACE($11,'whatsapp:','')) > 0 THEN _protocol = (SELECT protocol FROM public.tb_oc_tickets where date_end is null and src = $7 and dst = REPLACE($11,'whatsapp:','') order by date_start desc limit 1); _status = (SELECT status FROM public.tb_oc_tickets where protocol = _protocol); _assignedby = (SELECT assignedby FROM public.tb_oc_tickets where protocol = _protocol and status > 1)::text; if _assignedby is null then _assignedby = '0'; END IF; ELSE _status = 0; _protocol = (select public.fn_get_oc_protocol()); INSERT INTO public.tb_oc_tickets(protocol, protocol_src, oc_contact_id, channel, src, dst,status) VALUES (_protocol, _protocol, _id_contact, 'whatsapp', $7, REPLACE($11,'whatsapp:',''), 0); END IF; INSERT INTO public.tb_whatapp_inbound(mediacontenttype, smsmessagesid, nummedia, smsstatus, smssid, body, src, numsegments, messagesid, accountsid, dst, mediaurl, apiversion, date, errorcode, datesent, dateupdate, errormessage, ticket_id, coletado,protocol,profilename,notifyname,author,isforwarded,forwardingscore) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,_protocol,_profilename,_notifyname,_author,_isforwarded,_forwardingscore); RETURN _protocol::text || '|' || _status::text || '|' || _assignedby; END; 
$_$;


ALTER FUNCTION public.fn_insert_new_oc_message_ivr(_mediacontenttype character varying, _smsmessagesid character varying, _nummedia integer, _smsstatus integer, _smssid character varying, _body text, _src character varying, _numsegments integer, _messagesid character varying, _accountsid character varying, _dst character varying, _mediaurl text, _apiversion date, _date timestamp without time zone, _errorcode character varying, _datesent timestamp without time zone, _dateupdate timestamp without time zone, _errormessage character varying, _ticket_id uuid, _coletado boolean, _profilename text, _notifyname text, _author text, _isforwarded boolean, _forwardingscore smallint) OWNER TO gravador;

--
-- TOC entry 305 (class 1255 OID 3638711)
-- Name: fn_insert_new_oc_message_out(character varying, character varying, text, bigint, character varying, text, bigint); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_insert_new_oc_message_out(_src character varying, _dst character varying, _body text, _agente bigint, _mediacontenttype character varying, _mediaurl text, _prototocol bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$
 DECLARE _protocol bigint; DECLARE _idmsg bigint; DECLARE _id_contact integer; BEGIN if _prototocol = 0 or _prototocol = null then _protocol = (select public.fn_get_oc_protocol()); _id_contact = (select id_contact from tb_oc_contact_connections where connection = REPLACE(_dst,'whatsapp:','') limit 1); INSERT INTO public.tb_oc_tickets(protocol, protocol_src, oc_contact_id, channel, src, dst,status,assignedby) VALUES (_protocol, _protocol, _id_contact, 'whatsapp', _src, REPLACE(_dst,'whatsapp:',''), 3,_agente); else _protocol = _prototocol; end if; INSERT INTO public.tb_whatapp_outbound (smsstatus, body, src, dst,agente,mediaurl,mediacontenttype,protocol) VALUES (0, _body, _src, _dst,_agente,_mediaurl,_mediacontenttype,_protocol) RETURNING idmsg INTO _idmsg; RETURN _protocol::text || '|' || _idmsg::text; END; 
$$;


ALTER FUNCTION public.fn_insert_new_oc_message_out(_src character varying, _dst character varying, _body text, _agente bigint, _mediacontenttype character varying, _mediaurl text, _prototocol bigint) OWNER TO gravador;

--
-- TOC entry 306 (class 1255 OID 3638712)
-- Name: fn_insert_new_oc_message_out(character varying, character varying, text, bigint, character varying, text, bigint, boolean); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.fn_insert_new_oc_message_out(_src character varying, _dst character varying, _body text, _agente bigint, _mediacontenttype character varying, _mediaurl text, _prototocol bigint, _ismodel boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
 DECLARE _protocol bigint; DECLARE _idmsg bigint; DECLARE _id_contact integer; BEGIN if _prototocol = 0 or _prototocol = null then _protocol = (select public.fn_get_oc_protocol()); _id_contact = (select id_contact from tb_oc_contact_connections where connection = REPLACE(_dst,'whatsapp:','') limit 1); INSERT INTO public.tb_oc_tickets(protocol, protocol_src, oc_contact_id, channel, src, dst,status,assignedby) VALUES (_protocol, _protocol, _id_contact, 'whatsapp', _src, REPLACE(_dst,'whatsapp:',''), 3,_agente); else _protocol = _prototocol; end if; INSERT INTO public.tb_whatapp_outbound (smsstatus, body, src, dst,agente,mediaurl,mediacontenttype,protocol) VALUES (0, case when _mediaurl is null and _ismodel = false then (select REPLACE(REPLACE((select valor from infos where tipo=80),'{AGENTE}',(select nickname from tb_agentes where id = _agente)),'{GRUPO}',(select case when virtualgroup is null then '' else virtualgroup end from tb_oc_tickets where protocol = _protocol))) || _body else _body end , _src, _dst,_agente,_mediaurl,_mediacontenttype,_protocol) RETURNING idmsg INTO _idmsg; RETURN _protocol::text || '|' || _idmsg::text || '|◙' || case when _mediaurl is null and _ismodel = false then (select REPLACE(REPLACE((select valor from infos where tipo=80),'{AGENTE}',(select nickname from tb_agentes where id = _agente)),'{GRUPO}',(select case when virtualgroup is null then '' else virtualgroup end from tb_oc_tickets where protocol = _protocol))) || _body else _body end; END; 
$$;


ALTER FUNCTION public.fn_insert_new_oc_message_out(_src character varying, _dst character varying, _body text, _agente bigint, _mediacontenttype character varying, _mediaurl text, _prototocol bigint, _ismodel boolean) OWNER TO gravador;

--
-- TOC entry 307 (class 1255 OID 3638713)
-- Name: insert_contact_whatsapp(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.insert_contact_whatsapp(_numero text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
 id_ INTEGER;
BEGIN
IF NOT EXISTS(SELECT "connection" FROM tb_oc_contact_connections WHERE "connection" = _numero)
  THEN
INSERT INTO tb_oc_contact (firstname,lastname,displayname) SELECT _numero,'',_numero 
	WHERE NOT EXISTS (SELECT firstname FROM tb_oc_contact WHERE firstname = _numero) returning id into id_;
	INSERT INTO tb_oc_contact_connections (id_contact,"connection",medias,"type") SELECT id_, _numero,'{WhatsApp}','Outros' 
	WHERE NOT EXISTS (SELECT "connection" FROM tb_oc_contact_connections WHERE "connection" = _numero);
	RETURN True;
	ELSE
	RETURN False;
  END IF;
END;
$$;


ALTER FUNCTION public.insert_contact_whatsapp(_numero text) OWNER TO gravador;

--
-- TOC entry 308 (class 1255 OID 3638714)
-- Name: insert_contact_whatsapp(text, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.insert_contact_whatsapp(_numero text, _name text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$ DECLARE id_ INTEGER; BEGIN IF NOT EXISTS(SELECT "connection" FROM tb_oc_contact_connections WHERE "connection" = _numero) THEN INSERT INTO tb_oc_contact (firstname,lastname,displayname) SELECT _name,'',_name || ' ' || _numero WHERE NOT EXISTS (SELECT firstname FROM tb_oc_contact WHERE firstname = _name) returning id into id_; INSERT INTO tb_oc_contact_connections (id_contact,"connection",medias,"type") SELECT id_, _numero,'{WhatsApp}','Outros' WHERE NOT EXISTS (SELECT "connection" FROM tb_oc_contact_connections WHERE "connection" = _numero); RETURN True; ELSE Update tb_oc_contact set firstname=_name,displayname=_name where firstname=_numero and displayname<>_name; RETURN False; END IF; END; $$;


ALTER FUNCTION public.insert_contact_whatsapp(_numero text, _name text) OWNER TO gravador;

--
-- TOC entry 309 (class 1255 OID 3638715)
-- Name: n_serv(timestamp without time zone, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE OR REPLACE FUNCTION public.n_serv(
	timestamp without time zone,
	timestamp without time zone,
	text)
    RETURNS nserv_result
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
select
sum(COALESCE(case when modo='UV' and atendida = true then 1 else 0 end,0)) as atendidas,
sum(case when date_end is not null and agente_start is null and modo='UV' and atendida = False then 1 else 0 end) as natendidas,
cast(sum(case when (agente_end - agente_start) <= o_serv and atendida=true then 1 else 0 end)as float8) as o_serv,
cast(sum(case when (date_end - acd_start) >= o_fila and atendida=false then 1 else 0 end)as float8) as o_fila,
sum(case when (agente_start - acd_start) < o_fila and atendida=true then 1 else 0 end) as o_atendida,
cast(sum(case when (date_end - acd_start) <= o_fila and atendida=false then 1 else 0 end)as float8) as i_fila,
cast(sum(case when modo='UV' then 1 else 0 end)as float) as tot_chamadas,
(select valor from infos where tipo = '2') as nservico,(select NOW() as data),
(SELECT count(*) FROM tb_chamadas ch where ch.date_start between $1 and $2 and ch.modo = 'S' and ch.virtual_group = $3) as chamadas_out
from tb_chamadas 
left join tb_virtual_groups on tb_virtual_groups.virtual_group = tb_chamadas.virtual_group  
where acd_start between $1 and $2 and tb_chamadas.virtual_group = $3 group by tb_chamadas.virtual_group
$BODY$;


ALTER FUNCTION public.n_serv(timestamp without time zone, timestamp without time zone, text) OWNER TO gravador;

--
-- TOC entry 310 (class 1255 OID 3638716)
-- Name: n_serv_ani(timestamp without time zone, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.n_serv_ani(timestamp without time zone, timestamp without time zone, text) RETURNS public.nserv_result
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


ALTER FUNCTION public.n_serv_ani(timestamp without time zone, timestamp without time zone, text) OWNER TO root;

--
-- TOC entry 311 (class 1255 OID 3638717)
-- Name: rel_agentes(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_agentes(text) RETURNS TABLE(n_agente character varying, id integer, date date, atendidas bigint, tma interval, ttf interval, tempo_intervalo interval, tempo_refe interval)
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


ALTER FUNCTION public.rel_agentes(text) OWNER TO gravador;

--
-- TOC entry 312 (class 1255 OID 3638718)
-- Name: rel_billing(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_billing(text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf text, virtual_grp character varying, n_agente character varying, tab_1 text, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, dur_fila interval)
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


ALTER FUNCTION public.rel_billing(text) OWNER TO gravador;

--
-- TOC entry 313 (class 1255 OID 3638719)
-- Name: rel_billing_h(text, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_billing_h(text, text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf text, virtual_grp character varying, n_agente character varying, tab_1 text, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, dur_fila interval)
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


ALTER FUNCTION public.rel_billing_h(text, text) OWNER TO gravador;

--
-- TOC entry 314 (class 1255 OID 3638720)
-- Name: rel_billing_new(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_billing_new(text) RETURNS TABLE(channel character varying, count bigint, modo character varying, uniqueid character varying, ani character varying, dnis character varying, extension character varying, outgoing_call character varying, date_start timestamp without time zone, virtual_tranf character varying, agente_tranf character varying, date_agente_tranf timestamp without time zone, tab_1_tranf character varying, virtual_grp character varying, n_agente character varying, tab_1 character varying, date_ini timestamp without time zone, h_agente boolean, date_end timestamp with time zone, atendida boolean, dur_total interval, transf_ext character varying, abandonada_menor_20 integer, abandonada_maior_20 integer, atendida_menor_20 integer, atendida_maior_20 integer, abandonada_menor_30 integer, abandonada_maior_30 integer, atendida_menor_30 integer, atendida_maior_30 integer)
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


ALTER FUNCTION public.rel_billing_new(text) OWNER TO gravador;

--
-- TOC entry 315 (class 1255 OID 3638721)
-- Name: rel_noturno(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_noturno(text) RETURNS TABLE(virtual_grp character varying, intervalo time without time zone, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior interval, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
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


ALTER FUNCTION public.rel_noturno(text) OWNER TO gravador;

--
-- TOC entry 316 (class 1255 OID 3638722)
-- Name: rel_noturno_bil(text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_noturno_bil(text) RETURNS TABLE(virtual_grp character varying, intervalo time without time zone, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior time without time zone, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
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


ALTER FUNCTION public.rel_noturno_bil(text) OWNER TO gravador;

--
-- TOC entry 317 (class 1255 OID 3638723)
-- Name: rel_noturno_bil_sumario(text, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_noturno_bil_sumario(text, text) RETURNS TABLE(virtual_grp character varying, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior time without time zone, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
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


ALTER FUNCTION public.rel_noturno_bil_sumario(text, text) OWNER TO gravador;

--
-- TOC entry 318 (class 1255 OID 3638724)
-- Name: rel_noturno_sumario(text, text); Type: FUNCTION; Schema: public; Owner: gravador
--

CREATE FUNCTION public.rel_noturno_sumario(text, text) RETURNS TABLE(virtual_grp character varying, t_lig bigint, atendidas bigint, t_t_falado interval, abandonadas bigint, maior interval, medio interval, _20 bigint, m_20 bigint, a_20 bigint, a_m_20 bigint, a_30 bigint, a_m_30 bigint, aa_30 bigint, aa_m_30 bigint, t_lig_out bigint)
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


ALTER FUNCTION public.rel_noturno_sumario(text, text) OWNER TO gravador;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 201 (class 1259 OID 3638734)
-- Name: infos; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.infos (
    tipo integer NOT NULL,
    valor character varying(64)
);


ALTER TABLE public.infos OWNER TO gravador;

--
-- TOC entry 202 (class 1259 OID 3638737)
-- Name: login; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.login (
    "user" character varying(60) NOT NULL,
    pass character varying(60),
    tipo character varying(32),
    vrt_grp character varying(300),
    lgpd boolean DEFAULT false NOT NULL
);


ALTER TABLE public.login OWNER TO gravador;

--
-- TOC entry 203 (class 1259 OID 3638741)
-- Name: logo; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.logo (
    id integer NOT NULL,
    file bytea
);


ALTER TABLE public.logo OWNER TO gravador;

--
-- TOC entry 204 (class 1259 OID 3638747)
-- Name: motivosdepausa; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.motivosdepausa (
    id character varying(2) NOT NULL,
    decricao character varying(20),
    tempo time without time zone NOT NULL,
    produtiva boolean DEFAULT false NOT NULL,
    supervisionada boolean DEFAULT false NOT NULL
);


ALTER TABLE public.motivosdepausa OWNER TO gravador;

--
-- TOC entry 205 (class 1259 OID 3638752)
-- Name: rec_middleware; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.rec_middleware (
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


ALTER TABLE public.rec_middleware OWNER TO gravador;

--
-- TOC entry 206 (class 1259 OID 3638758)
-- Name: rec_middleware_serial_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.rec_middleware_serial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rec_middleware_serial_seq OWNER TO gravador;

--
-- TOC entry 4345 (class 0 OID 0)
-- Dependencies: 206
-- Name: rec_middleware_serial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.rec_middleware_serial_seq OWNED BY public.rec_middleware.serial;


--
-- TOC entry 207 (class 1259 OID 3638760)
-- Name: seq_protocol; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.seq_protocol
    START WITH 2022082600020
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 2099082600001
    CACHE 1;


ALTER TABLE public.seq_protocol OWNER TO gravador;

--
-- TOC entry 208 (class 1259 OID 3638762)
-- Name: tb_ag_grupo; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_ag_grupo (
    id integer NOT NULL,
    agente bigint,
    virtual_grp character varying(32),
    priority integer DEFAULT 0
);


ALTER TABLE public.tb_ag_grupo OWNER TO gravador;

--
-- TOC entry 209 (class 1259 OID 3638766)
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_ag_grupo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_ag_grupo_id_seq OWNER TO gravador;

--
-- TOC entry 4346 (class 0 OID 0)
-- Dependencies: 209
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_ag_grupo_id_seq OWNED BY public.tb_ag_grupo.id;


--
-- TOC entry 210 (class 1259 OID 3638768)
-- Name: tb_agente_log; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_agente_log (
    id bigint NOT NULL,
    agente bigint,
    extension character varying(40),
    data_ini timestamp with time zone,
    data_fim timestamp with time zone,
    tipo smallint,
    tp_pausa character varying(2)
);


ALTER TABLE public.tb_agente_log OWNER TO gravador;

--
-- TOC entry 211 (class 1259 OID 3638771)
-- Name: tb_agente_log_detalhado; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_agente_log_detalhado (
    id bigint NOT NULL,
    fkiduser bigint,
    date timestamp without time zone,
    tp integer,
    id_intervalo character varying(2)
);


ALTER TABLE public.tb_agente_log_detalhado OWNER TO gravador;

--
-- TOC entry 212 (class 1259 OID 3638774)
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_agente_log_detalhado_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_agente_log_detalhado_id_seq OWNER TO gravador;

--
-- TOC entry 4347 (class 0 OID 0)
-- Dependencies: 212
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_agente_log_detalhado_id_seq OWNED BY public.tb_agente_log_detalhado.id;


--
-- TOC entry 213 (class 1259 OID 3638776)
-- Name: tb_agente_log_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_agente_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_agente_log_id_seq OWNER TO gravador;

--
-- TOC entry 4348 (class 0 OID 0)
-- Dependencies: 213
-- Name: tb_agente_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_agente_log_id_seq OWNED BY public.tb_agente_log.id;


--
-- TOC entry 214 (class 1259 OID 3638778)
-- Name: tb_agente_status; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_agente_status (
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


ALTER TABLE public.tb_agente_status OWNER TO gravador;

--
-- TOC entry 215 (class 1259 OID 3638787)
-- Name: tb_agentes; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_agentes (
    id bigint NOT NULL,
    n_agente character varying(100),
    nickname character varying(30),
    ativo boolean DEFAULT false NOT NULL,
    historico boolean DEFAULT false NOT NULL,
    historico_recs boolean DEFAULT false NOT NULL,
    notgrp character varying(32) DEFAULT ''::character varying NOT NULL,
    profilepic text,
    secret text DEFAULT '43d063b5fa593d86c16ad79a60cee2b7'::text NOT NULL
);


ALTER TABLE public.tb_agentes OWNER TO gravador;

--
-- TOC entry 216 (class 1259 OID 3638798)
-- Name: tb_ani; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_ani (
    nome character varying(64) NOT NULL,
    ativo boolean
);


ALTER TABLE public.tb_ani OWNER TO gravador;

--
-- TOC entry 217 (class 1259 OID 3638801)
-- Name: tb_ani_route; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_ani_route (
    serial integer NOT NULL,
    numero character varying(32) NOT NULL,
    nome character varying(32),
    priority integer NOT NULL,
    r_route boolean NOT NULL,
    dest_r_route character varying(40) NOT NULL,
    ani character varying(32) NOT NULL,
    ani_name integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tb_ani_route OWNER TO gravador;

--
-- TOC entry 218 (class 1259 OID 3638805)
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_ani_route_serial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_ani_route_serial_seq OWNER TO gravador;

--
-- TOC entry 4349 (class 0 OID 0)
-- Dependencies: 218
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_ani_route_serial_seq OWNED BY public.tb_ani_route.serial;


--
-- TOC entry 219 (class 1259 OID 3638807)
-- Name: tb_anuncios; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_anuncios (
    anuncio character varying(150) NOT NULL
);


ALTER TABLE public.tb_anuncios OWNER TO gravador;

--
-- TOC entry 220 (class 1259 OID 3638810)
-- Name: tb_billing; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_billing (
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


ALTER TABLE public.tb_billing OWNER TO gravador;

--
-- TOC entry 221 (class 1259 OID 3638816)
-- Name: tb_billing_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_billing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_billing_id_seq OWNER TO gravador;

--
-- TOC entry 4350 (class 0 OID 0)
-- Dependencies: 221
-- Name: tb_billing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_billing_id_seq OWNED BY public.tb_billing.id;


--
-- TOC entry 222 (class 1259 OID 3638818)
-- Name: tb_camp; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_camp (
    id integer NOT NULL,
    nom_camp character varying(64),
    data_ini timestamp without time zone NOT NULL,
    data_end timestamp without time zone NOT NULL,
    quota integer NOT NULL,
    paral_disc integer,
    parl_disc_ag integer DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT false NOT NULL,
    t_p_numero integer DEFAULT 5 NOT NULL
);


ALTER TABLE public.tb_camp OWNER TO gravador;

--
-- TOC entry 281 (class 1259 OID 3639651)
-- Name: tb_camp_10000; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_camp_10000 (
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


ALTER TABLE public.tb_camp_10000 OWNER TO gravador;

--
-- TOC entry 223 (class 1259 OID 3638824)
-- Name: tb_camp_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_camp_id_seq
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    MAXVALUE 99999
    CACHE 1;


ALTER TABLE public.tb_camp_id_seq OWNER TO gravador;

--
-- TOC entry 4351 (class 0 OID 0)
-- Dependencies: 223
-- Name: tb_camp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_camp_id_seq OWNED BY public.tb_camp.id;


--
-- TOC entry 224 (class 1259 OID 3638826)
-- Name: tb_chamadas; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_chamadas (
    uniqueid character varying(36) NOT NULL,
    channel character varying(80),
    ani character varying(32),
    agente bigint,
    extension character varying(40),
    dnis character varying(32),
    virtual_group text,
    outgoing_call character varying(32),
    date_start timestamp without time zone,
    acd_start timestamp without time zone,
    agente_start timestamp without time zone,
    agente_end timestamp without time zone,
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
    dialinidate timestamp without time zone,
    date_end timestamp without time zone,
    custom_vars text,
    date_end_tab timestamp without time zone,
    real_dial_number character varying(32),
    cdr_tipo character varying(10),
    cdr_tipo_abreviaddo character varying(5),
    cdr_localizacao character varying(32),
    cdr_custo numeric,
    dest_channel character varying(32),
    protocol bigint
);


ALTER TABLE public.tb_chamadas OWNER TO gravador;

--
-- TOC entry 225 (class 1259 OID 3638837)
-- Name: tb_codigos; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_codigos (
    codigo character varying(8) NOT NULL,
    facilidade character varying(20)
);


ALTER TABLE public.tb_codigos OWNER TO gravador;

--
-- TOC entry 226 (class 1259 OID 3638840)
-- Name: tb_dialer; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_dialer (
    id integer NOT NULL,
    n_disc character varying(32) NOT NULL,
    info1 character varying(128),
    status smallint DEFAULT 0,
    ramal character varying(6),
    agente integer,
    data timestamp without time zone,
    camp integer
);


ALTER TABLE public.tb_dialer OWNER TO gravador;

--
-- TOC entry 227 (class 1259 OID 3638844)
-- Name: tb_dialer_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_dialer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_dialer_id_seq OWNER TO gravador;

--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 227
-- Name: tb_dialer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_dialer_id_seq OWNED BY public.tb_dialer.id;


--
-- TOC entry 228 (class 1259 OID 3638846)
-- Name: tb_dialercallback; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_dialercallback (
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


ALTER TABLE public.tb_dialercallback OWNER TO gravador;

--
-- TOC entry 229 (class 1259 OID 3638858)
-- Name: tb_dialercallback_CampID_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public."tb_dialercallback_CampID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."tb_dialercallback_CampID_seq" OWNER TO gravador;

--
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 229
-- Name: tb_dialercallback_CampID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public."tb_dialercallback_CampID_seq" OWNED BY public.tb_dialercallback.camp_id;


--
-- TOC entry 230 (class 1259 OID 3638860)
-- Name: tb_dialercallback_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tb_dialercallback_log (
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


ALTER TABLE public.tb_dialercallback_log OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 3638865)
-- Name: tb_dialercallback_num; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_dialercallback_num (
    id integer NOT NULL,
    id_cliente character varying(20),
    tel character varying(20) NOT NULL,
    contato character varying(64),
    campos character varying(1000),
    valores character varying(1000),
    obs character varying(1000),
    status integer DEFAULT 0 NOT NULL,
    pausado boolean DEFAULT false NOT NULL,
    camp_id integer NOT NULL,
    playback_custom character varying(20),
    data_agendamento timestamp without time zone DEFAULT now() NOT NULL,
    data_last timestamp without time zone DEFAULT now() NOT NULL,
    n_tentativas integer DEFAULT 0 NOT NULL,
    abortado integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tb_dialercallback_num OWNER TO gravador;

--
-- TOC entry 232 (class 1259 OID 3638877)
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_dialercallback_num_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_dialercallback_num_id_seq OWNER TO gravador;

--
-- TOC entry 4354 (class 0 OID 0)
-- Dependencies: 232
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_dialercallback_num_id_seq OWNED BY public.tb_dialercallback_num.id;


--
-- TOC entry 233 (class 1259 OID 3638879)
-- Name: tb_dnis; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_dnis (
    dnis character varying(8) NOT NULL,
    obs character varying(200),
    time_condition character varying(32)
);


ALTER TABLE public.tb_dnis OWNER TO gravador;

--
-- TOC entry 234 (class 1259 OID 3638882)
-- Name: tb_dt_chamadas; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_dt_chamadas (
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
    priority integer DEFAULT 0 NOT NULL,
    r_ani_name integer,
    tab character varying
);


ALTER TABLE public.tb_dt_chamadas OWNER TO gravador;

--
-- TOC entry 235 (class 1259 OID 3638889)
-- Name: tb_facilidades; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_facilidades (
    facilidade character varying(30),
    recurso character varying(30) NOT NULL,
    tipo integer
);


ALTER TABLE public.tb_facilidades OWNER TO gravador;

--
-- TOC entry 236 (class 1259 OID 3638892)
-- Name: tb_internalchat; Type: TABLE; Schema: public; Owner: callproadmin
--

CREATE TABLE public.tb_internalchat (
    id bigint NOT NULL,
    date_send timestamp without time zone DEFAULT now() NOT NULL,
    dst bigint NOT NULL,
    src bigint NOT NULL,
    msg text,
    read smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.tb_internalchat OWNER TO callproadmin;

--
-- TOC entry 237 (class 1259 OID 3638900)
-- Name: tb_internalchat_id_seq; Type: SEQUENCE; Schema: public; Owner: callproadmin
--

CREATE SEQUENCE public.tb_internalchat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_internalchat_id_seq OWNER TO callproadmin;

--
-- TOC entry 4355 (class 0 OID 0)
-- Dependencies: 237
-- Name: tb_internalchat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: callproadmin
--

ALTER SEQUENCE public.tb_internalchat_id_seq OWNED BY public.tb_internalchat.id;


--
-- TOC entry 238 (class 1259 OID 3638902)
-- Name: tb_interval_rel; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_interval_rel (
    intervalo time without time zone NOT NULL
);


ALTER TABLE public.tb_interval_rel OWNER TO gravador;

--
-- TOC entry 239 (class 1259 OID 3638905)
-- Name: tb_ivr_oc_whatsapp; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_ivr_oc_whatsapp (
    id integer NOT NULL,
    json character varying NOT NULL
);


ALTER TABLE public.tb_ivr_oc_whatsapp OWNER TO gravador;

--
-- TOC entry 240 (class 1259 OID 3638911)
-- Name: tb_ivr_oc_whatsapp_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_ivr_oc_whatsapp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_ivr_oc_whatsapp_id_seq OWNER TO gravador;

--
-- TOC entry 4356 (class 0 OID 0)
-- Dependencies: 240
-- Name: tb_ivr_oc_whatsapp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_ivr_oc_whatsapp_id_seq OWNED BY public.tb_ivr_oc_whatsapp.id;


--
-- TOC entry 241 (class 1259 OID 3638913)
-- Name: tb_log; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_log (
    usuario character varying(50),
    data timestamp without time zone DEFAULT now() NOT NULL,
    tipo integer DEFAULT 0,
    evento character varying(30000)
);


ALTER TABLE public.tb_log OWNER TO gravador;

--
-- TOC entry 242 (class 1259 OID 3638921)
-- Name: tb_musiconhold; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_musiconhold (
    classe character varying(50) NOT NULL,
    _mode character varying(10),
    directory character varying(200),
    sort character varying(10)
);


ALTER TABLE public.tb_musiconhold OWNER TO gravador;

--
-- TOC entry 243 (class 1259 OID 3638924)
-- Name: tb_oc_atend_log; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_atend_log (
    idmsg bigint NOT NULL,
    protocol bigint NOT NULL,
    agente bigint,
    body text,
    date timestamp without time zone DEFAULT now() NOT NULL,
    sttype integer DEFAULT 0 NOT NULL,
    supervisor character varying(50)
);


ALTER TABLE public.tb_oc_atend_log OWNER TO gravador;

--
-- TOC entry 244 (class 1259 OID 3638932)
-- Name: tb_oc_atend_log_idmsg_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_atend_log_idmsg_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_atend_log_idmsg_seq OWNER TO gravador;

--
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 244
-- Name: tb_oc_atend_log_idmsg_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_atend_log_idmsg_seq OWNED BY public.tb_oc_atend_log.idmsg;


--
-- TOC entry 245 (class 1259 OID 3638934)
-- Name: tb_oc_contact; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_contact (
    id integer NOT NULL,
    firstname text NOT NULL,
    lastname text NOT NULL,
    displayname text NOT NULL
);


ALTER TABLE public.tb_oc_contact OWNER TO gravador;

--
-- TOC entry 246 (class 1259 OID 3638940)
-- Name: tb_oc_contact_connections; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_contact_connections (
    id integer NOT NULL,
    id_contact integer NOT NULL,
    connection text NOT NULL,
    medias character varying(16)[],
    type character varying(16)
);


ALTER TABLE public.tb_oc_contact_connections OWNER TO gravador;

--
-- TOC entry 247 (class 1259 OID 3638946)
-- Name: tb_oc_contact_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_contact_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_contact_connections_id_seq OWNER TO gravador;

--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 247
-- Name: tb_oc_contact_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_contact_connections_id_seq OWNED BY public.tb_oc_contact_connections.id;


--
-- TOC entry 248 (class 1259 OID 3638948)
-- Name: tb_oc_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_contact_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_contact_id_seq OWNER TO gravador;

--
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 248
-- Name: tb_oc_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_contact_id_seq OWNED BY public.tb_oc_contact.id;


--
-- TOC entry 249 (class 1259 OID 3638950)
-- Name: tb_oc_messages; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_messages (
    id integer NOT NULL,
    type integer NOT NULL,
    msg text NOT NULL,
    src text
);


ALTER TABLE public.tb_oc_messages OWNER TO gravador;

--
-- TOC entry 250 (class 1259 OID 3638956)
-- Name: tb_oc_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_messages_id_seq OWNER TO gravador;

--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 250
-- Name: tb_oc_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_messages_id_seq OWNED BY public.tb_oc_messages.id;


--
-- TOC entry 251 (class 1259 OID 3638958)
-- Name: tb_oc_senders; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_senders (
    id integer NOT NULL,
    description text,
    sender text NOT NULL,
    broker character varying(20) NOT NULL,
    is_authenticated boolean DEFAULT false NOT NULL,
    qr_code_b64 text,
    acl text[],
    ivr text
);


ALTER TABLE public.tb_oc_senders OWNER TO gravador;

--
-- TOC entry 252 (class 1259 OID 3638965)
-- Name: tb_oc_senders_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_senders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_senders_id_seq OWNER TO gravador;

--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 252
-- Name: tb_oc_senders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_senders_id_seq OWNED BY public.tb_oc_senders.id;


--
-- TOC entry 253 (class 1259 OID 3638967)
-- Name: tb_oc_tags; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_tags (
    id integer NOT NULL,
    id_contact integer NOT NULL,
    keytag text NOT NULL,
    valuetag text NOT NULL
);


ALTER TABLE public.tb_oc_tags OWNER TO gravador;

--
-- TOC entry 254 (class 1259 OID 3638973)
-- Name: tb_oc_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_tags_id_seq OWNER TO gravador;

--
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 254
-- Name: tb_oc_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_tags_id_seq OWNED BY public.tb_oc_tags.id;


--
-- TOC entry 255 (class 1259 OID 3638975)
-- Name: tb_oc_tickets; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_oc_tickets (
    id integer NOT NULL,
    protocol bigint NOT NULL,
    protocol_src bigint,
    oc_contact_id integer NOT NULL,
    channel character varying(50) NOT NULL,
    src character varying(50) NOT NULL,
    dst character varying(50) NOT NULL,
    assignedby bigint,
    date_start timestamp without time zone DEFAULT now() NOT NULL,
    acd_start timestamp without time zone,
    agente_start timestamp without time zone,
    agente_end timestamp without time zone,
    date_end timestamp without time zone,
    status integer DEFAULT 0 NOT NULL,
    virtualgroup character varying
);


ALTER TABLE public.tb_oc_tickets OWNER TO gravador;

--
-- TOC entry 256 (class 1259 OID 3638983)
-- Name: tb_oc_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_oc_tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_oc_tickets_id_seq OWNER TO gravador;

--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 256
-- Name: tb_oc_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_oc_tickets_id_seq OWNED BY public.tb_oc_tickets.id;


--
-- TOC entry 257 (class 1259 OID 3638985)
-- Name: tb_queues; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_queues (
    name character varying(32) NOT NULL,
    script character varying(300) NOT NULL
);


ALTER TABLE public.tb_queues OWNER TO gravador;

--
-- TOC entry 258 (class 1259 OID 3638988)
-- Name: tb_ramais; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_ramais (
    id integer NOT NULL,
    tecnologia character varying(50),
    ramal character varying(40),
    softphone integer DEFAULT 0 NOT NULL,
    softphone_video integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tb_ramais OWNER TO gravador;

--
-- TOC entry 259 (class 1259 OID 3638993)
-- Name: tb_ramais_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_ramais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_ramais_id_seq OWNER TO gravador;

--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 259
-- Name: tb_ramais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_ramais_id_seq OWNED BY public.tb_ramais.id;


--
-- TOC entry 260 (class 1259 OID 3638995)
-- Name: tb_rel_ani; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_rel_ani (
    num character varying(32) NOT NULL,
    text character varying(64),
    grupo character varying(32)
);


ALTER TABLE public.tb_rel_ani OWNER TO gravador;

--
-- TOC entry 261 (class 1259 OID 3638998)
-- Name: tb_rel_virtual_group; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_rel_virtual_group (
    grupo character varying(60) NOT NULL
);


ALTER TABLE public.tb_rel_virtual_group OWNER TO gravador;

--
-- TOC entry 262 (class 1259 OID 3639001)
-- Name: tb_sms_conf_alerta; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_sms_conf_alerta (
    numero character varying(6) NOT NULL,
    string character varying(160),
    sms_s character varying(300)
);


ALTER TABLE public.tb_sms_conf_alerta OWNER TO gravador;

--
-- TOC entry 263 (class 1259 OID 3639004)
-- Name: tb_sms_received; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_sms_received (
    id integer NOT NULL,
    sender character varying(16),
    sent timestamp without time zone,
    status character varying(20),
    message character varying(200),
    read boolean DEFAULT false NOT NULL,
    resend character varying(40),
    idsms text
);


ALTER TABLE public.tb_sms_received OWNER TO gravador;

--
-- TOC entry 264 (class 1259 OID 3639011)
-- Name: tb_sms_received_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_sms_received_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_sms_received_id_seq OWNER TO gravador;

--
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 264
-- Name: tb_sms_received_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_sms_received_id_seq OWNED BY public.tb_sms_received.id;


--
-- TOC entry 265 (class 1259 OID 3639013)
-- Name: tb_sms_send; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_sms_send (
    id integer NOT NULL,
    id_tipo integer,
    desc_tipo character varying(100),
    num_sms character varying(16),
    texto text,
    status integer,
    data timestamp without time zone DEFAULT now() NOT NULL,
    "user" character varying(50) DEFAULT 'SERVIDOR'::character varying NOT NULL,
    msgid integer DEFAULT 0,
    read integer DEFAULT 0,
    idsms text,
    receiver text,
    cost double precision
);


ALTER TABLE public.tb_sms_send OWNER TO gravador;

--
-- TOC entry 266 (class 1259 OID 3639023)
-- Name: tb_sms_send_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_sms_send_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_sms_send_id_seq OWNER TO gravador;

--
-- TOC entry 4366 (class 0 OID 0)
-- Dependencies: 266
-- Name: tb_sms_send_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_sms_send_id_seq OWNED BY public.tb_sms_send.id;


--
-- TOC entry 267 (class 1259 OID 3639025)
-- Name: tb_smsinbound_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_smsinbound_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_smsinbound_id_seq OWNER TO gravador;

--
-- TOC entry 268 (class 1259 OID 3639027)
-- Name: tb_smsoutbound_idmsg_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_smsoutbound_idmsg_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_smsoutbound_idmsg_seq OWNER TO gravador;

--
-- TOC entry 269 (class 1259 OID 3639029)
-- Name: tb_tabs; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_tabs (
    tab character varying(32) NOT NULL,
    valores character varying(1000) NOT NULL
);


ALTER TABLE public.tb_tabs OWNER TO gravador;

--
-- TOC entry 270 (class 1259 OID 3639035)
-- Name: tb_time_conditions; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_time_conditions (
    name character varying(32) NOT NULL,
    script character varying
)
WITH (autovacuum_enabled='true');


ALTER TABLE public.tb_time_conditions OWNER TO gravador;

--
-- TOC entry 271 (class 1259 OID 3639041)
-- Name: tb_trunks; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_trunks (
    tronco character varying(60) NOT NULL,
    aliases character varying(60),
    tipo character varying(10)
);


ALTER TABLE public.tb_trunks OWNER TO gravador;

--
-- TOC entry 272 (class 1259 OID 3639044)
-- Name: tb_uf; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_uf (
    num character varying(32) NOT NULL,
    text character varying(64)
);


ALTER TABLE public.tb_uf OWNER TO gravador;

--
-- TOC entry 273 (class 1259 OID 3639047)
-- Name: tb_virtual_groups; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_virtual_groups (
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
    priority integer DEFAULT 0 NOT NULL,
    h_base smallint DEFAULT 0 NOT NULL,
    hs_turn smallint DEFAULT 24 NOT NULL
);


ALTER TABLE public.tb_virtual_groups OWNER TO gravador;

--
-- TOC entry 274 (class 1259 OID 3639061)
-- Name: tb_whatapp_inbound; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_whatapp_inbound (
    id bigint DEFAULT nextval('public.tb_smsinbound_id_seq'::regclass) NOT NULL,
    mediacontenttype text,
    smsmessagesid character varying(50),
    nummedia smallint,
    smsstatus smallint,
    smssid character varying(50),
    body text,
    src character varying(50),
    numsegments smallint,
    messagesid character varying(50),
    accountsid character varying(50),
    dst character varying(50),
    mediaurl text,
    apiversion date,
    date timestamp without time zone DEFAULT now() NOT NULL,
    errorcode character varying(20),
    datesent timestamp without time zone,
    dateupdate timestamp without time zone,
    errormessage character varying(50),
    ticket_id uuid,
    coletado boolean DEFAULT false,
    agente bigint,
    protocol bigint,
    latitude numeric(6,4),
    longitude numeric(6,4),
    is_menu boolean DEFAULT false,
    menu_local character varying,
    profilename text,
    notifyname text,
    author text,
    isforwarded boolean DEFAULT false NOT NULL,
    forwardingscore smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.tb_whatapp_inbound OWNER TO gravador;

--
-- TOC entry 275 (class 1259 OID 3639073)
-- Name: tb_whatapp_outbound; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_whatapp_outbound (
    idmsg bigint DEFAULT nextval('public.tb_smsoutbound_idmsg_seq'::regclass) NOT NULL,
    mediacontenttype text,
    smsmessagesid character varying(50),
    nummedia smallint,
    smsstatus smallint DEFAULT 0 NOT NULL,
    smssid character varying(50),
    body text,
    src character varying(50),
    numsegments smallint,
    messagesid character varying(50),
    accountsid character varying(50),
    dst character varying(50),
    mediaurl text,
    apiversion date,
    date timestamp without time zone DEFAULT now() NOT NULL,
    errorcode character varying(20),
    datesent timestamp without time zone,
    dateupdate timestamp without time zone,
    errormessage character varying(50),
    ticket_id uuid,
    coletado boolean DEFAULT false,
    is_template boolean,
    agente bigint,
    protocol bigint,
    latitude numeric(6,4),
    longitude numeric(6,4)
);


ALTER TABLE public.tb_whatapp_outbound OWNER TO gravador;

--
-- TOC entry 276 (class 1259 OID 3639083)
-- Name: tb_whatapp_smsstatus; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_whatapp_smsstatus (
    id bigint DEFAULT nextval('public.tb_whatapp_smsstatus'::regclass) NOT NULL,
    statuskey smallint,
    statusvalue character varying(50)
);


ALTER TABLE public.tb_whatapp_smsstatus OWNER TO gravador;

--
-- TOC entry 277 (class 1259 OID 3639087)
-- Name: tb_whatsapp_template; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tb_whatsapp_template (
    id integer NOT NULL,
    language character varying(32) DEFAULT 'Portuguese (BR)'::character varying NOT NULL,
    message text NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    istemplate boolean DEFAULT false NOT NULL,
    category text DEFAULT 'Geral'::text NOT NULL,
    isenabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tb_whatsapp_template OWNER TO gravador;

--
-- TOC entry 278 (class 1259 OID 3639098)
-- Name: tb_whatsapp_template_id_seq; Type: SEQUENCE; Schema: public; Owner: gravador
--

CREATE SEQUENCE public.tb_whatsapp_template_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tb_whatsapp_template_id_seq OWNER TO gravador;

--
-- TOC entry 4367 (class 0 OID 0)
-- Dependencies: 278
-- Name: tb_whatsapp_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gravador
--

ALTER SEQUENCE public.tb_whatsapp_template_id_seq OWNED BY public.tb_whatsapp_template.id;


--
-- TOC entry 279 (class 1259 OID 3639100)
-- Name: tbl; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.tbl (
    id integer,
    ts time without time zone
);


ALTER TABLE public.tbl OWNER TO gravador;

--
-- TOC entry 280 (class 1259 OID 3639103)
-- Name: td_dias_esp; Type: TABLE; Schema: public; Owner: gravador
--

CREATE TABLE public.td_dias_esp (
    date timestamp without time zone NOT NULL,
    "Name" character varying(32)
);


ALTER TABLE public.td_dias_esp OWNER TO gravador;

--
-- TOC entry 3910 (class 2604 OID 3639107)
-- Name: rec_middleware serial; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.rec_middleware ALTER COLUMN serial SET DEFAULT nextval('public.rec_middleware_serial_seq'::regclass);


--
-- TOC entry 3911 (class 2604 OID 3639108)
-- Name: tb_ag_grupo id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ag_grupo ALTER COLUMN id SET DEFAULT nextval('public.tb_ag_grupo_id_seq'::regclass);


--
-- TOC entry 3913 (class 2604 OID 3639109)
-- Name: tb_agente_log id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agente_log ALTER COLUMN id SET DEFAULT nextval('public.tb_agente_log_id_seq'::regclass);


--
-- TOC entry 3914 (class 2604 OID 3639110)
-- Name: tb_agente_log_detalhado id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agente_log_detalhado ALTER COLUMN id SET DEFAULT nextval('public.tb_agente_log_detalhado_id_seq'::regclass);


--
-- TOC entry 3923 (class 2604 OID 3639111)
-- Name: tb_ani_route serial; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ani_route ALTER COLUMN serial SET DEFAULT nextval('public.tb_ani_route_serial_seq'::regclass);


--
-- TOC entry 3925 (class 2604 OID 3639112)
-- Name: tb_billing id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_billing ALTER COLUMN id SET DEFAULT nextval('public.tb_billing_id_seq'::regclass);


--
-- TOC entry 3926 (class 2604 OID 3639113)
-- Name: tb_camp id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_camp ALTER COLUMN id SET DEFAULT nextval('public.tb_camp_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 3639114)
-- Name: tb_dialer id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dialer ALTER COLUMN id SET DEFAULT nextval('public.tb_dialer_id_seq'::regclass);


--
-- TOC entry 3937 (class 2604 OID 3639115)
-- Name: tb_dialercallback camp_id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dialercallback ALTER COLUMN camp_id SET DEFAULT nextval('public."tb_dialercallback_CampID_seq"'::regclass);


--
-- TOC entry 3946 (class 2604 OID 3639116)
-- Name: tb_dialercallback_num id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dialercallback_num ALTER COLUMN id SET DEFAULT nextval('public.tb_dialercallback_num_id_seq'::regclass);


--
-- TOC entry 3954 (class 2604 OID 3639117)
-- Name: tb_internalchat id; Type: DEFAULT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY public.tb_internalchat ALTER COLUMN id SET DEFAULT nextval('public.tb_internalchat_id_seq'::regclass);


--
-- TOC entry 3957 (class 2604 OID 3639118)
-- Name: tb_ivr_oc_whatsapp id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ivr_oc_whatsapp ALTER COLUMN id SET DEFAULT nextval('public.tb_ivr_oc_whatsapp_id_seq'::regclass);


--
-- TOC entry 3960 (class 2604 OID 3639119)
-- Name: tb_oc_atend_log idmsg; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_atend_log ALTER COLUMN idmsg SET DEFAULT nextval('public.tb_oc_atend_log_idmsg_seq'::regclass);


--
-- TOC entry 3963 (class 2604 OID 3639120)
-- Name: tb_oc_contact id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_contact_id_seq'::regclass);


--
-- TOC entry 3964 (class 2604 OID 3639121)
-- Name: tb_oc_contact_connections id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact_connections ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_contact_connections_id_seq'::regclass);


--
-- TOC entry 3965 (class 2604 OID 3639122)
-- Name: tb_oc_messages id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_messages ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_messages_id_seq'::regclass);


--
-- TOC entry 3966 (class 2604 OID 3639123)
-- Name: tb_oc_senders id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_senders ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_senders_id_seq'::regclass);


--
-- TOC entry 3968 (class 2604 OID 3639124)
-- Name: tb_oc_tags id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_tags ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_tags_id_seq'::regclass);


--
-- TOC entry 3969 (class 2604 OID 3639125)
-- Name: tb_oc_tickets id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_tickets ALTER COLUMN id SET DEFAULT nextval('public.tb_oc_tickets_id_seq'::regclass);


--
-- TOC entry 3972 (class 2604 OID 3639126)
-- Name: tb_ramais id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ramais ALTER COLUMN id SET DEFAULT nextval('public.tb_ramais_id_seq'::regclass);


--
-- TOC entry 3975 (class 2604 OID 3639127)
-- Name: tb_sms_received id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_sms_received ALTER COLUMN id SET DEFAULT nextval('public.tb_sms_received_id_seq'::regclass);


--
-- TOC entry 3977 (class 2604 OID 3639128)
-- Name: tb_sms_send id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_sms_send ALTER COLUMN id SET DEFAULT nextval('public.tb_sms_send_id_seq'::regclass);


--
-- TOC entry 4004 (class 2604 OID 3639129)
-- Name: tb_whatsapp_template id; Type: DEFAULT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_whatsapp_template ALTER COLUMN id SET DEFAULT nextval('public.tb_whatsapp_template_id_seq'::regclass);


--
-- TOC entry 4258 (class 0 OID 3638734)
-- Dependencies: 201
-- Data for Name: infos; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.infos (tipo, valor) FROM stdin;
\.


--
-- TOC entry 4259 (class 0 OID 3638737)
-- Dependencies: 202
-- Data for Name: login; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.login ("user", pass, tipo, vrt_grp, lgpd) FROM stdin;
\.


--
-- TOC entry 4260 (class 0 OID 3638741)
-- Dependencies: 203
-- Data for Name: logo; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.logo (id, file) FROM stdin;
\.


--
-- TOC entry 4261 (class 0 OID 3638747)
-- Dependencies: 204
-- Data for Name: motivosdepausa; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.motivosdepausa (id, decricao, tempo, produtiva, supervisionada) FROM stdin;
\.


--
-- TOC entry 4262 (class 0 OID 3638752)
-- Dependencies: 205
-- Data for Name: rec_middleware; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.rec_middleware (uniqueid, channel, exten, outgoing_call, date_start, date_end, path, record, conv, dur_file, end_rec, serial) FROM stdin;
\.


--
-- TOC entry 4265 (class 0 OID 3638762)
-- Dependencies: 208
-- Data for Name: tb_ag_grupo; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_ag_grupo (id, agente, virtual_grp, priority) FROM stdin;
\.


--
-- TOC entry 4267 (class 0 OID 3638768)
-- Dependencies: 210
-- Data for Name: tb_agente_log; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_agente_log (id, agente, extension, data_ini, data_fim, tipo, tp_pausa) FROM stdin;
\.


--
-- TOC entry 4268 (class 0 OID 3638771)
-- Dependencies: 211
-- Data for Name: tb_agente_log_detalhado; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_agente_log_detalhado (id, fkiduser, date, tp, id_intervalo) FROM stdin;
\.


--
-- TOC entry 4271 (class 0 OID 3638778)
-- Dependencies: 214
-- Data for Name: tb_agente_status; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_agente_status (id, status, channel, tecnologia, tp_de_pausa, date_status, dialer, "TAB_wait", "DIALER_CAMPANHA", "DIALER_CLIENTE", "DIALER_CAMPOS", "DIALER_VALORES", "DIALER_STATUS") FROM stdin;
\.


--
-- TOC entry 4272 (class 0 OID 3638787)
-- Dependencies: 215
-- Data for Name: tb_agentes; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_agentes (id, n_agente, nickname, ativo, historico, historico_recs, notgrp, profilepic, secret) FROM stdin;
\.


--
-- TOC entry 4273 (class 0 OID 3638798)
-- Dependencies: 216
-- Data for Name: tb_ani; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_ani (nome, ativo) FROM stdin;
\.


--
-- TOC entry 4274 (class 0 OID 3638801)
-- Dependencies: 217
-- Data for Name: tb_ani_route; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_ani_route (serial, numero, nome, priority, r_route, dest_r_route, ani, ani_name) FROM stdin;
\.


--
-- TOC entry 4276 (class 0 OID 3638807)
-- Dependencies: 219
-- Data for Name: tb_anuncios; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_anuncios (anuncio) FROM stdin;
\.


--
-- TOC entry 4277 (class 0 OID 3638810)
-- Dependencies: 220
-- Data for Name: tb_billing; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_billing (id, tipo_ligacao, callid, ani, dnis, data_sistema, hora_sistema, grupo_atendimentoinicial, atendente_atendimentoinicial, data_atendimentoinicial, hora_atendimentoinicial, grupo, data_pa, hora_pa, data_abandono, hora_abandono, responsavel_abandono, data_desligada, hora_desligada, atendente, tempo_chamada, tempo_fila, local_abandono, resultado_transferencia, resultado_atendente, tipo_transferenciaexterna, numero_transferenciaexterna, coletado) FROM stdin;
\.


--
-- TOC entry 4279 (class 0 OID 3638818)
-- Dependencies: 222
-- Data for Name: tb_camp; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_camp (id, nom_camp, data_ini, data_end, quota, paral_disc, parl_disc_ag, ativo, t_p_numero) FROM stdin;
\.


--
-- TOC entry 4338 (class 0 OID 3639651)
-- Dependencies: 281
-- Data for Name: tb_camp_10000; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_camp_10000 (tel, contato, status, data_agendamento, data_last, n_tentativas, abortado, campos, valores, obs) FROM stdin;
\.


--
-- TOC entry 4281 (class 0 OID 3638826)
-- Dependencies: 224
-- Data for Name: tb_chamadas; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_chamadas (uniqueid, channel, ani, agente, extension, dnis, virtual_group, outgoing_call, date_start, acd_start, agente_start, agente_end, modo, atendida, record, a_agente, v_score, conv, dur_file, tab_1, tab_2, h_agente, d_uniqueid, dialstatus, dialinidate, date_end, custom_vars, date_end_tab, real_dial_number, cdr_tipo, cdr_tipo_abreviaddo, cdr_localizacao, cdr_custo, dest_channel, protocol) FROM stdin;
\.


--
-- TOC entry 4282 (class 0 OID 3638837)
-- Dependencies: 225
-- Data for Name: tb_codigos; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_codigos (codigo, facilidade) FROM stdin;
\.


--
-- TOC entry 4283 (class 0 OID 3638840)
-- Dependencies: 226
-- Data for Name: tb_dialer; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_dialer (id, n_disc, info1, status, ramal, agente, data, camp) FROM stdin;
\.


--
-- TOC entry 4285 (class 0 OID 3638846)
-- Dependencies: 228
-- Data for Name: tb_dialercallback; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_dialercallback (camp_id, camp_name, ativo, virtualgroup, digits_map, digits_timeout, playback, qmaxfila, qdisc_p_agent, qdisc_simult, q_preload) FROM stdin;
\.


--
-- TOC entry 4287 (class 0 OID 3638860)
-- Dependencies: 230
-- Data for Name: tb_dialercallback_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tb_dialercallback_log (id, id_tb_num, id_cliente, tel, data_discagem, data_hangup, data_agi, data_rfila, status, uniqueid, digit, dest, coletado) FROM stdin;
\.


--
-- TOC entry 4288 (class 0 OID 3638865)
-- Dependencies: 231
-- Data for Name: tb_dialercallback_num; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_dialercallback_num (id, id_cliente, tel, contato, campos, valores, obs, status, pausado, camp_id, playback_custom, data_agendamento, data_last, n_tentativas, abortado) FROM stdin;
\.


--
-- TOC entry 4290 (class 0 OID 3638879)
-- Dependencies: 233
-- Data for Name: tb_dnis; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_dnis (dnis, obs, time_condition) FROM stdin;
\.


--
-- TOC entry 4291 (class 0 OID 3638882)
-- Dependencies: 234
-- Data for Name: tb_dt_chamadas; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_dt_chamadas (uniqueid, channel, ani_name, ani_num, last_date, actionid_response, virtual_group, t_timeout, d_timeout, t_wait_agente, r_agente_time, script, queue, sendaction, t_score, o_serv, priority, r_ani_name, tab) FROM stdin;
\.


--
-- TOC entry 4292 (class 0 OID 3638889)
-- Dependencies: 235
-- Data for Name: tb_facilidades; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_facilidades (facilidade, recurso, tipo) FROM stdin;
\.


--
-- TOC entry 4293 (class 0 OID 3638892)
-- Dependencies: 236
-- Data for Name: tb_internalchat; Type: TABLE DATA; Schema: public; Owner: callproadmin
--

COPY public.tb_internalchat (id, date_send, dst, src, msg, read) FROM stdin;
\.


--
-- TOC entry 4295 (class 0 OID 3638902)
-- Dependencies: 238
-- Data for Name: tb_interval_rel; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_interval_rel (intervalo) FROM stdin;
\.


--
-- TOC entry 4296 (class 0 OID 3638905)
-- Dependencies: 239
-- Data for Name: tb_ivr_oc_whatsapp; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_ivr_oc_whatsapp (id, json) FROM stdin;
\.


--
-- TOC entry 4298 (class 0 OID 3638913)
-- Dependencies: 241
-- Data for Name: tb_log; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_log (usuario, data, tipo, evento) FROM stdin;
\.


--
-- TOC entry 4299 (class 0 OID 3638921)
-- Dependencies: 242
-- Data for Name: tb_musiconhold; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_musiconhold (classe, _mode, directory, sort) FROM stdin;
\.


--
-- TOC entry 4300 (class 0 OID 3638924)
-- Dependencies: 243
-- Data for Name: tb_oc_atend_log; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_atend_log (idmsg, protocol, agente, body, date, sttype, supervisor) FROM stdin;
\.


--
-- TOC entry 4302 (class 0 OID 3638934)
-- Dependencies: 245
-- Data for Name: tb_oc_contact; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_contact (id, firstname, lastname, displayname) FROM stdin;
\.


--
-- TOC entry 4303 (class 0 OID 3638940)
-- Dependencies: 246
-- Data for Name: tb_oc_contact_connections; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_contact_connections (id, id_contact, connection, medias, type) FROM stdin;
\.


--
-- TOC entry 4306 (class 0 OID 3638950)
-- Dependencies: 249
-- Data for Name: tb_oc_messages; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_messages (id, type, msg, src) FROM stdin;
\.


--
-- TOC entry 4308 (class 0 OID 3638958)
-- Dependencies: 251
-- Data for Name: tb_oc_senders; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_senders (id, description, sender, broker, is_authenticated, qr_code_b64, acl, ivr) FROM stdin;
\.


--
-- TOC entry 4310 (class 0 OID 3638967)
-- Dependencies: 253
-- Data for Name: tb_oc_tags; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_tags (id, id_contact, keytag, valuetag) FROM stdin;
\.


--
-- TOC entry 4312 (class 0 OID 3638975)
-- Dependencies: 255
-- Data for Name: tb_oc_tickets; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_oc_tickets (id, protocol, protocol_src, oc_contact_id, channel, src, dst, assignedby, date_start, acd_start, agente_start, agente_end, date_end, status, virtualgroup) FROM stdin;
\.


--
-- TOC entry 4314 (class 0 OID 3638985)
-- Dependencies: 257
-- Data for Name: tb_queues; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_queues (name, script) FROM stdin;
\.


--
-- TOC entry 4315 (class 0 OID 3638988)
-- Dependencies: 258
-- Data for Name: tb_ramais; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_ramais (id, tecnologia, ramal, softphone, softphone_video) FROM stdin;
\.


--
-- TOC entry 4317 (class 0 OID 3638995)
-- Dependencies: 260
-- Data for Name: tb_rel_ani; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_rel_ani (num, text, grupo) FROM stdin;
\.


--
-- TOC entry 4318 (class 0 OID 3638998)
-- Dependencies: 261
-- Data for Name: tb_rel_virtual_group; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_rel_virtual_group (grupo) FROM stdin;
\.


--
-- TOC entry 4319 (class 0 OID 3639001)
-- Dependencies: 262
-- Data for Name: tb_sms_conf_alerta; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_sms_conf_alerta (numero, string, sms_s) FROM stdin;
\.


--
-- TOC entry 4320 (class 0 OID 3639004)
-- Dependencies: 263
-- Data for Name: tb_sms_received; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_sms_received (id, sender, sent, status, message, read, resend, idsms) FROM stdin;
\.


--
-- TOC entry 4322 (class 0 OID 3639013)
-- Dependencies: 265
-- Data for Name: tb_sms_send; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_sms_send (id, id_tipo, desc_tipo, num_sms, texto, status, data, "user", msgid, read, idsms, receiver, cost) FROM stdin;
\.


--
-- TOC entry 4326 (class 0 OID 3639029)
-- Dependencies: 269
-- Data for Name: tb_tabs; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_tabs (tab, valores) FROM stdin;
\.


--
-- TOC entry 4327 (class 0 OID 3639035)
-- Dependencies: 270
-- Data for Name: tb_time_conditions; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_time_conditions (name, script) FROM stdin;
\.


--
-- TOC entry 4328 (class 0 OID 3639041)
-- Dependencies: 271
-- Data for Name: tb_trunks; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_trunks (tronco, aliases, tipo) FROM stdin;
\.


--
-- TOC entry 4329 (class 0 OID 3639044)
-- Dependencies: 272
-- Data for Name: tb_uf; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_uf (num, text) FROM stdin;
\.


--
-- TOC entry 4330 (class 0 OID 3639047)
-- Dependencies: 273
-- Data for Name: tb_virtual_groups; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_virtual_groups (virtual_group, queue, t_timeout, d_timeout, t_wait_agente, r_agente_time, dest_tranb, t_scoring, o_serv, o_fila, tab, t_tab, priority, h_base, hs_turn) FROM stdin;
\.


--
-- TOC entry 4331 (class 0 OID 3639061)
-- Dependencies: 274
-- Data for Name: tb_whatapp_inbound; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_whatapp_inbound (id, mediacontenttype, smsmessagesid, nummedia, smsstatus, smssid, body, src, numsegments, messagesid, accountsid, dst, mediaurl, apiversion, date, errorcode, datesent, dateupdate, errormessage, ticket_id, coletado, agente, protocol, latitude, longitude, is_menu, menu_local, profilename, notifyname, author, isforwarded, forwardingscore) FROM stdin;
\.


--
-- TOC entry 4332 (class 0 OID 3639073)
-- Dependencies: 275
-- Data for Name: tb_whatapp_outbound; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_whatapp_outbound (idmsg, mediacontenttype, smsmessagesid, nummedia, smsstatus, smssid, body, src, numsegments, messagesid, accountsid, dst, mediaurl, apiversion, date, errorcode, datesent, dateupdate, errormessage, ticket_id, coletado, is_template, agente, protocol, latitude, longitude) FROM stdin;
\.


--
-- TOC entry 4333 (class 0 OID 3639083)
-- Dependencies: 276
-- Data for Name: tb_whatapp_smsstatus; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_whatapp_smsstatus (id, statuskey, statusvalue) FROM stdin;
\.


--
-- TOC entry 4334 (class 0 OID 3639087)
-- Dependencies: 277
-- Data for Name: tb_whatsapp_template; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tb_whatsapp_template (id, language, message, description, istemplate, category, isenabled) FROM stdin;
\.


--
-- TOC entry 4336 (class 0 OID 3639100)
-- Dependencies: 279
-- Data for Name: tbl; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.tbl (id, ts) FROM stdin;
\.


--
-- TOC entry 4337 (class 0 OID 3639103)
-- Dependencies: 280
-- Data for Name: td_dias_esp; Type: TABLE DATA; Schema: public; Owner: gravador
--

COPY public.td_dias_esp (date, "Name") FROM stdin;
\.


--
-- TOC entry 4368 (class 0 OID 0)
-- Dependencies: 206
-- Name: rec_middleware_serial_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.rec_middleware_serial_seq', 1, false);


--
-- TOC entry 4369 (class 0 OID 0)
-- Dependencies: 207
-- Name: seq_protocol; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.seq_protocol', 2022082600020, false);


--
-- TOC entry 4370 (class 0 OID 0)
-- Dependencies: 209
-- Name: tb_ag_grupo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_ag_grupo_id_seq', 1, false);


--
-- TOC entry 4371 (class 0 OID 0)
-- Dependencies: 212
-- Name: tb_agente_log_detalhado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_agente_log_detalhado_id_seq', 1, false);


--
-- TOC entry 4372 (class 0 OID 0)
-- Dependencies: 213
-- Name: tb_agente_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_agente_log_id_seq', 1, false);


--
-- TOC entry 4373 (class 0 OID 0)
-- Dependencies: 218
-- Name: tb_ani_route_serial_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_ani_route_serial_seq', 1, false);


--
-- TOC entry 4374 (class 0 OID 0)
-- Dependencies: 221
-- Name: tb_billing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_billing_id_seq', 1, false);


--
-- TOC entry 4375 (class 0 OID 0)
-- Dependencies: 223
-- Name: tb_camp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_camp_id_seq', 10000, false);


--
-- TOC entry 4376 (class 0 OID 0)
-- Dependencies: 227
-- Name: tb_dialer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_dialer_id_seq', 1, false);


--
-- TOC entry 4377 (class 0 OID 0)
-- Dependencies: 229
-- Name: tb_dialercallback_CampID_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public."tb_dialercallback_CampID_seq"', 1, false);


--
-- TOC entry 4378 (class 0 OID 0)
-- Dependencies: 232
-- Name: tb_dialercallback_num_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_dialercallback_num_id_seq', 1, false);


--
-- TOC entry 4379 (class 0 OID 0)
-- Dependencies: 237
-- Name: tb_internalchat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: callproadmin
--

SELECT pg_catalog.setval('public.tb_internalchat_id_seq', 1, false);


--
-- TOC entry 4380 (class 0 OID 0)
-- Dependencies: 240
-- Name: tb_ivr_oc_whatsapp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_ivr_oc_whatsapp_id_seq', 1, false);


--
-- TOC entry 4381 (class 0 OID 0)
-- Dependencies: 244
-- Name: tb_oc_atend_log_idmsg_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_atend_log_idmsg_seq', 1, false);


--
-- TOC entry 4382 (class 0 OID 0)
-- Dependencies: 247
-- Name: tb_oc_contact_connections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_contact_connections_id_seq', 1, false);


--
-- TOC entry 4383 (class 0 OID 0)
-- Dependencies: 248
-- Name: tb_oc_contact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_contact_id_seq', 1, false);


--
-- TOC entry 4384 (class 0 OID 0)
-- Dependencies: 250
-- Name: tb_oc_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_messages_id_seq', 1, false);


--
-- TOC entry 4385 (class 0 OID 0)
-- Dependencies: 252
-- Name: tb_oc_senders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_senders_id_seq', 1, false);


--
-- TOC entry 4386 (class 0 OID 0)
-- Dependencies: 254
-- Name: tb_oc_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_tags_id_seq', 1, false);


--
-- TOC entry 4387 (class 0 OID 0)
-- Dependencies: 256
-- Name: tb_oc_tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_oc_tickets_id_seq', 1, false);


--
-- TOC entry 4388 (class 0 OID 0)
-- Dependencies: 259
-- Name: tb_ramais_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_ramais_id_seq', 1, false);


--
-- TOC entry 4389 (class 0 OID 0)
-- Dependencies: 264
-- Name: tb_sms_received_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_sms_received_id_seq', 1, false);


--
-- TOC entry 4390 (class 0 OID 0)
-- Dependencies: 266
-- Name: tb_sms_send_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_sms_send_id_seq', 1, false);


--
-- TOC entry 4391 (class 0 OID 0)
-- Dependencies: 267
-- Name: tb_smsinbound_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_smsinbound_id_seq', 1, false);


--
-- TOC entry 4392 (class 0 OID 0)
-- Dependencies: 268
-- Name: tb_smsoutbound_idmsg_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_smsoutbound_idmsg_seq', 1, false);


--
-- TOC entry 4393 (class 0 OID 0)
-- Dependencies: 278
-- Name: tb_whatsapp_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gravador
--

SELECT pg_catalog.setval('public.tb_whatsapp_template_id_seq', 1, false);


--
-- TOC entry 4014 (class 2606 OID 3639133)
-- Name: infos infos_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.infos
    ADD CONSTRAINT infos_pkey PRIMARY KEY (tipo);


--
-- TOC entry 4016 (class 2606 OID 3639135)
-- Name: login login_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_pkey PRIMARY KEY ("user");


--
-- TOC entry 4018 (class 2606 OID 3639137)
-- Name: logo logo_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.logo
    ADD CONSTRAINT logo_pkey PRIMARY KEY (id);


--
-- TOC entry 4020 (class 2606 OID 3639139)
-- Name: motivosdepausa motivosdepausa_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.motivosdepausa
    ADD CONSTRAINT motivosdepausa_pkey PRIMARY KEY (id);


--
-- TOC entry 4022 (class 2606 OID 3639141)
-- Name: rec_middleware rec_middleware_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.rec_middleware
    ADD CONSTRAINT rec_middleware_pkey PRIMARY KEY (serial);


--
-- TOC entry 4024 (class 2606 OID 3639143)
-- Name: tb_ag_grupo tb_ag_grupo_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_pkey PRIMARY KEY (id);


--
-- TOC entry 4028 (class 2606 OID 3639145)
-- Name: tb_agente_log_detalhado tb_agente_log_detalhado_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agente_log_detalhado
    ADD CONSTRAINT tb_agente_log_detalhado_pkey PRIMARY KEY (id);


--
-- TOC entry 4026 (class 2606 OID 3639147)
-- Name: tb_agente_log tb_agente_log_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agente_log
    ADD CONSTRAINT tb_agente_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4030 (class 2606 OID 3639149)
-- Name: tb_agente_status tb_agente_status_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agente_status
    ADD CONSTRAINT tb_agente_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4032 (class 2606 OID 3639151)
-- Name: tb_agentes tb_agentes_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_agentes
    ADD CONSTRAINT tb_agentes_pkey PRIMARY KEY (id);


--
-- TOC entry 4034 (class 2606 OID 3639153)
-- Name: tb_ani tb_ani_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ani
    ADD CONSTRAINT tb_ani_pkey PRIMARY KEY (nome);


--
-- TOC entry 4036 (class 2606 OID 3639155)
-- Name: tb_ani_route tb_ani_route_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ani_route
    ADD CONSTRAINT tb_ani_route_pkey PRIMARY KEY (serial);


--
-- TOC entry 4038 (class 2606 OID 3639157)
-- Name: tb_billing tb_billing_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_billing
    ADD CONSTRAINT tb_billing_pkey PRIMARY KEY (id);


--
-- TOC entry 4122 (class 2606 OID 3639661)
-- Name: tb_camp_10000 tb_camp_10000_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_camp_10000
    ADD CONSTRAINT tb_camp_10000_pkey PRIMARY KEY (tel);


--
-- TOC entry 4040 (class 2606 OID 3639159)
-- Name: tb_camp tb_camp_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_camp
    ADD CONSTRAINT tb_camp_pkey PRIMARY KEY (id);


--
-- TOC entry 4050 (class 2606 OID 3639161)
-- Name: tb_chamadas tb_chamadas_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_chamadas
    ADD CONSTRAINT tb_chamadas_pkey PRIMARY KEY (uniqueid);


--
-- TOC entry 4052 (class 2606 OID 3639163)
-- Name: tb_codigos tb_codigos_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_codigos
    ADD CONSTRAINT tb_codigos_pkey PRIMARY KEY (codigo);


--
-- TOC entry 4056 (class 2606 OID 3639165)
-- Name: tb_dialercallback_num tb_dialercallback_num_pk; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dialercallback_num
    ADD CONSTRAINT tb_dialercallback_num_pk PRIMARY KEY (id);


--
-- TOC entry 4054 (class 2606 OID 3639167)
-- Name: tb_dialercallback tb_dialercallback_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dialercallback
    ADD CONSTRAINT tb_dialercallback_pkey PRIMARY KEY (camp_id);


--
-- TOC entry 4058 (class 2606 OID 3639169)
-- Name: tb_dnis tb_dnis_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dnis
    ADD CONSTRAINT tb_dnis_pkey PRIMARY KEY (dnis);


--
-- TOC entry 4061 (class 2606 OID 3639171)
-- Name: tb_dt_chamadas tb_dt_chamadas_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_dt_chamadas
    ADD CONSTRAINT tb_dt_chamadas_pkey PRIMARY KEY (uniqueid);


--
-- TOC entry 4063 (class 2606 OID 3639173)
-- Name: tb_facilidades tb_facilidades_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_facilidades
    ADD CONSTRAINT tb_facilidades_pkey PRIMARY KEY (recurso);


--
-- TOC entry 4065 (class 2606 OID 3639175)
-- Name: tb_internalchat tb_internalchat_pkey; Type: CONSTRAINT; Schema: public; Owner: callproadmin
--

ALTER TABLE ONLY public.tb_internalchat
    ADD CONSTRAINT tb_internalchat_pkey PRIMARY KEY (id);


--
-- TOC entry 4067 (class 2606 OID 3639177)
-- Name: tb_interval_rel tb_interval_rel_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_interval_rel
    ADD CONSTRAINT tb_interval_rel_pkey PRIMARY KEY (intervalo);


--
-- TOC entry 4069 (class 2606 OID 3639179)
-- Name: tb_ivr_oc_whatsapp tb_ivr_oc_whatsapp_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ivr_oc_whatsapp
    ADD CONSTRAINT tb_ivr_oc_whatsapp_pkey PRIMARY KEY (id);


--
-- TOC entry 4071 (class 2606 OID 3639181)
-- Name: tb_musiconhold tb_musiconhold_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_musiconhold
    ADD CONSTRAINT tb_musiconhold_pkey PRIMARY KEY (classe);


--
-- TOC entry 4073 (class 2606 OID 3639183)
-- Name: tb_oc_atend_log tb_oc_atend_log_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_atend_log
    ADD CONSTRAINT tb_oc_atend_log_pkey PRIMARY KEY (idmsg);


--
-- TOC entry 4077 (class 2606 OID 3639185)
-- Name: tb_oc_contact_connections tb_oc_contact_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact_connections
    ADD CONSTRAINT tb_oc_contact_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 4079 (class 2606 OID 3639187)
-- Name: tb_oc_contact_connections tb_oc_contact_connections_un; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact_connections
    ADD CONSTRAINT tb_oc_contact_connections_un UNIQUE (connection);


--
-- TOC entry 4075 (class 2606 OID 3639189)
-- Name: tb_oc_contact tb_oc_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact
    ADD CONSTRAINT tb_oc_contact_pkey PRIMARY KEY (id);


--
-- TOC entry 4081 (class 2606 OID 3639191)
-- Name: tb_oc_messages tb_oc_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_messages
    ADD CONSTRAINT tb_oc_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 4083 (class 2606 OID 3639193)
-- Name: tb_oc_senders tb_oc_senders_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_senders
    ADD CONSTRAINT tb_oc_senders_pkey PRIMARY KEY (id);


--
-- TOC entry 4085 (class 2606 OID 3639195)
-- Name: tb_oc_tags tb_oc_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_tags
    ADD CONSTRAINT tb_oc_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 4087 (class 2606 OID 3639197)
-- Name: tb_oc_tickets tb_oc_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_tickets
    ADD CONSTRAINT tb_oc_tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 4089 (class 2606 OID 3639199)
-- Name: tb_queues tb_queues_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_queues
    ADD CONSTRAINT tb_queues_pkey PRIMARY KEY (name);


--
-- TOC entry 4091 (class 2606 OID 3639201)
-- Name: tb_ramais tb_ramais_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ramais
    ADD CONSTRAINT tb_ramais_pkey PRIMARY KEY (id);


--
-- TOC entry 4094 (class 2606 OID 3639203)
-- Name: tb_rel_virtual_group tb_rel_virtual_group_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_rel_virtual_group
    ADD CONSTRAINT tb_rel_virtual_group_pkey PRIMARY KEY (grupo);


--
-- TOC entry 4096 (class 2606 OID 3639205)
-- Name: tb_sms_conf_alerta tb_sms_conf_alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_sms_conf_alerta
    ADD CONSTRAINT tb_sms_conf_alerta_pkey PRIMARY KEY (numero);


--
-- TOC entry 4098 (class 2606 OID 3639207)
-- Name: tb_sms_received tb_sms_received_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_sms_received
    ADD CONSTRAINT tb_sms_received_pkey PRIMARY KEY (id);


--
-- TOC entry 4100 (class 2606 OID 3639209)
-- Name: tb_sms_send tb_sms_send_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_sms_send
    ADD CONSTRAINT tb_sms_send_pkey PRIMARY KEY (id);


--
-- TOC entry 4112 (class 2606 OID 3639211)
-- Name: tb_whatapp_inbound tb_smsinbound_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_whatapp_inbound
    ADD CONSTRAINT tb_smsinbound_pkey PRIMARY KEY (id);


--
-- TOC entry 4114 (class 2606 OID 3639213)
-- Name: tb_whatapp_outbound tb_smsoutbound_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_whatapp_outbound
    ADD CONSTRAINT tb_smsoutbound_pkey PRIMARY KEY (idmsg);


--
-- TOC entry 4116 (class 2606 OID 3639215)
-- Name: tb_whatapp_smsstatus tb_smsstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_whatapp_smsstatus
    ADD CONSTRAINT tb_smsstatus_pkey PRIMARY KEY (id);


--
-- TOC entry 4102 (class 2606 OID 3639217)
-- Name: tb_tabs tb_tabs_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_tabs
    ADD CONSTRAINT tb_tabs_pkey PRIMARY KEY (tab);


--
-- TOC entry 4104 (class 2606 OID 3639219)
-- Name: tb_time_conditions tb_time_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_time_conditions
    ADD CONSTRAINT tb_time_conditions_pkey PRIMARY KEY (name);


--
-- TOC entry 4106 (class 2606 OID 3639221)
-- Name: tb_trunks tb_trunks_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_trunks
    ADD CONSTRAINT tb_trunks_pkey PRIMARY KEY (tronco);


--
-- TOC entry 4108 (class 2606 OID 3639223)
-- Name: tb_uf tb_uf_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_uf
    ADD CONSTRAINT tb_uf_pkey PRIMARY KEY (num);


--
-- TOC entry 4110 (class 2606 OID 3639225)
-- Name: tb_virtual_groups tb_virtual_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_virtual_groups
    ADD CONSTRAINT tb_virtual_groups_pkey PRIMARY KEY (virtual_group);


--
-- TOC entry 4118 (class 2606 OID 3639227)
-- Name: tb_whatsapp_template tb_whatsapp_template_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_whatsapp_template
    ADD CONSTRAINT tb_whatsapp_template_pkey PRIMARY KEY (id);


--
-- TOC entry 4120 (class 2606 OID 3639229)
-- Name: td_dias_esp td_dias_esp_pkey; Type: CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.td_dias_esp
    ADD CONSTRAINT td_dias_esp_pkey PRIMARY KEY (date);


--
-- TOC entry 4041 (class 1259 OID 3639230)
-- Name: idx_channel; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_channel ON public.tb_chamadas USING btree (channel);


--
-- TOC entry 4092 (class 1259 OID 3639231)
-- Name: idx_rel_ani_grp; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_rel_ani_grp ON public.tb_rel_ani USING btree (num);


--
-- TOC entry 4042 (class 1259 OID 3639232)
-- Name: idx_tb_chamadas_acd_start; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_acd_start ON public.tb_chamadas USING btree (acd_start);


--
-- TOC entry 4043 (class 1259 OID 3639233)
-- Name: idx_tb_chamadas_agente_end; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_agente_end ON public.tb_chamadas USING btree (agente_end);


--
-- TOC entry 4044 (class 1259 OID 3639234)
-- Name: idx_tb_chamadas_agente_start; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_agente_start ON public.tb_chamadas USING btree (agente_start);


--
-- TOC entry 4045 (class 1259 OID 3639235)
-- Name: idx_tb_chamadas_date_end; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_date_end ON public.tb_chamadas USING btree (date_end);


--
-- TOC entry 4046 (class 1259 OID 3639236)
-- Name: idx_tb_chamadas_date_start; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_date_start ON public.tb_chamadas USING btree (date_start);


--
-- TOC entry 4047 (class 1259 OID 3639237)
-- Name: idx_tb_chamadas_modo; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_modo ON public.tb_chamadas USING btree (modo);


--
-- TOC entry 4048 (class 1259 OID 3639238)
-- Name: idx_tb_chamadas_virtual_group; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX idx_tb_chamadas_virtual_group ON public.tb_chamadas USING btree (virtual_group);


--
-- TOC entry 4059 (class 1259 OID 3639239)
-- Name: tb_dt_chamadas_lastdate; Type: INDEX; Schema: public; Owner: gravador
--

CREATE INDEX tb_dt_chamadas_lastdate ON public.tb_dt_chamadas USING btree (last_date);


--
-- TOC entry 4125 (class 2606 OID 3639240)
-- Name: tb_ani_route ani; Type: FK CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ani_route
    ADD CONSTRAINT ani FOREIGN KEY (ani) REFERENCES public.tb_ani(nome);


--
-- TOC entry 4123 (class 2606 OID 3639245)
-- Name: tb_ag_grupo tb_ag_grupo_agente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_agente_fkey FOREIGN KEY (agente) REFERENCES public.tb_agentes(id);


--
-- TOC entry 4124 (class 2606 OID 3639250)
-- Name: tb_ag_grupo tb_ag_grupo_virtual_grp_fkey; Type: FK CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_ag_grupo
    ADD CONSTRAINT tb_ag_grupo_virtual_grp_fkey FOREIGN KEY (virtual_grp) REFERENCES public.tb_virtual_groups(virtual_group);


--
-- TOC entry 4126 (class 2606 OID 3639255)
-- Name: tb_oc_contact_connections tb_oc_contact_connections_id_contact_fkey; Type: FK CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_contact_connections
    ADD CONSTRAINT tb_oc_contact_connections_id_contact_fkey FOREIGN KEY (id_contact) REFERENCES public.tb_oc_contact(id) NOT VALID;


--
-- TOC entry 4127 (class 2606 OID 3639260)
-- Name: tb_oc_tags tb_oc_tags_id_contact_fkey; Type: FK CONSTRAINT; Schema: public; Owner: gravador
--

ALTER TABLE ONLY public.tb_oc_tags
    ADD CONSTRAINT tb_oc_tags_id_contact_fkey FOREIGN KEY (id_contact) REFERENCES public.tb_oc_contact(id) NOT VALID;


--
-- TOC entry 4344 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2023-04-20 15:10:30

--
-- PostgreSQL database dump complete
--

