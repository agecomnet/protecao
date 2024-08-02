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

ALTER FUNCTION public.n_serv(timestamp without time zone, timestamp without time zone, text)
    OWNER TO gravador;

--
-- TOC entry 310 (class 1255 OID 3638716)
-- Name: n_serv_ani(timestamp without time zone, timestamp without time zone, text); Type: FUNCTION; Schema: public; Owner: root
--

--CREATE FUNCTION public.n_serv_ani(timestamp without time zone, timestamp without time zone, text) RETURNS public.nserv_result
 --   LANGUAGE sql
  --  AS $_$ SELECT
--	(select count(atendida) from tb_chamadas where outgoing_call=$3 and date_start > $1 and date_start < $2 and atendida = true and date_end is not null and modo = 'UV'),
--	(select count(atendida) from tb_chamadas where outgoing_call=$3 and date_start > $1 and date_start < $2 and atendida = false and date_end is not null and modo = 'UV'),
--	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (SELECT virtual_group FROM tb_virtual_groups) and
--	((agente_start - acd_start) <= (
--		select o_fila from tb_virtual_groups where tb_virtual_groups.virtual_group = tb_chamadas.virtual_group)
--	 and atendida=True and acd_start > $1 and acd_start < $2 and outgoing_call like $3 )),
--	(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where ((date_end - acd_start) >= ('00:00:20') and atendida=FALSE 
--		) and acd_start > $1 and acd_start < $2 and date_end is not null and outgoing_call like $3),
--		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in (
--		SELECT virtual_group FROM tb_virtual_groups) and ((date_end - acd_start) <= ('00:00:20') and atendida=FALSE 
--		) and acd_start > $1 and acd_start < $2 and outgoing_call=$3 and date_end is not null),
--		(SELECT cast(count(uniqueid)as float8) FROM tb_chamadas where virtual_group in 
--		(SELECT virtual_group FROM tb_virtual_groups) and acd_start > $1 and acd_start < $2 and outgoing_call like $3)
--		 ,(select valor from infos where tipo = '2'),(select NOW())-
	
 --$_$;


--ALTER FUNCTION public.n_serv_ani(timestamp without time zone, timestamp without time zone, text) OWNER TO root;

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

INSERT INTO public.infos(tipo, valor) VALUES ('1', 'Nome Cliente');
INSERT INTO public.infos(tipo, valor) VALUES ('2', '1');
INSERT INTO public.infos(tipo, valor) VALUES ('3', '5');
INSERT INTO public.infos(tipo, valor) VALUES ('4', '1');
INSERT INTO public.infos(tipo, valor) VALUES ('10', '5#5#10#10#30#60');
INSERT INTO public.infos(tipo, valor) VALUES ('12', '*{AGENTE}: *');
INSERT INTO public.infos(tipo, valor) VALUES ('80', '');
INSERT INTO public.infos(tipo, valor) VALUES ('81', '*Transferindo atendimento para: {AGENTE}*.');
INSERT INTO public.infos(tipo, valor) VALUES ('82', '*Transferindo atendimento para: {GRUPO}*.');
INSERT INTO public.infos(tipo, valor) VALUES ('83', 'Agradecemos seu contato. Seu atendimento com o protocolo: {PROTOCOLO} foi finalizado. Se precisar, entre em contato novamente, estamos à disposição.');
INSERT INTO public.infos(tipo, valor) VALUES ('91', '1');
INSERT INTO public.infos(tipo, valor) VALUES ('93', '0');
INSERT INTO public.logo VALUES (0, '\xffd8ffe000104a46494600010101000000000000ffdb0043000201010101010201010102020202020403020202020504040304060506060605060606070908060709070606080b08090a0a0a0a0a06080b0c0b0a0c090a0a0affdb004301020202020202050303050a0706070a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0affc20011080267026603012200021101031101ffc4001e000101000202030101000000000000000000010809070a0405060203ffc4001d010100020203010100000000000000000000070804060305090201ffda000c03010002100310000000dfc02cb02c000000000000000000000000000000000000000002c002c2c0005214802880148a12c0a214851148a25944a22c0b05948b014800000052288b02c0014800150000000148522c0521480000b288b0000000000005200522c05200000002ca200000000000000000000014800002c2c02c051288a2144a25944b0b0005948a2000288a22c00288522c0b0a08522c00288b02880b288000000a082a0582a5082800965128960b2c14102a0a949651005102808290582a0b0160a9410a94020282016525828082a000a1289651288a0002594025944b0582cb0a04a2148b059427aa3db4f45ee4fe850b0252288b00005944a22810b2c0b0508b028851288a258290580a20280000416512880b01651149660a99d5897d6df010df96016048e4be38fe7fb3f3eebd678e64ce6a6a487693d9ef42fe463bd9340fbce3eac859616504148594085961485815058a4a12825801601614128105214002580a45114400a3e7be7ba98197fa5dfe5e4fefe78deef3333c65b8130232ef9864bb007d0f2370c367d2f9c3e778c5c9c5e9b1832e1d0ed1a72e10dfde3a467346a3f213e438aa10b2ddc4b39ba0ff00679c4cedb3ac14214965214102c0b0148a202c5202c50010149651148b0a010b14405940082c51f2bf53d5f0c67c227dcf3e37f3dac7d6f215aea2c129c1a0000000781aded98355deb407e5e73607540f407b56ed2fa197729e8369ca59600520a1284508001445080289440500850004a00000941050080a713f45fef1bd588c1edc5fd17dfd9da58135d6e02c002a5202c0026abb6a5e9b4e90b439bd8fdfa3a5de8d763a1c391144a04a00416582a14094405414101412ca080a25128004a2292c051003f81d79f687a22dfef79aceb47d697a7cc50fbe3000000000000cfcd34e75f3ed4ebdb9d3c8da6bdca4513bc292ca428045852005944000b2928102c15054a10014021629160b058163e10fbbc44f3f0b4e07cbef67c332d409c1c2d75165800b00002c0580003f5badd286dfa0fb2dd7bbb487559ed4d59ee74b28815000b02c1628960b001602ca40504a004a85961400010a4288a3481bbed191a84d96e893f66c0b8ab135d87539d9b10d0a6faeca5390992bb816000b000b000e17e68c10d477fe12e65d7d29ff00a05905ddd3a0577ece9763f3251284b280105944280082c0b2894450944016165094000085944b2804d18ef3f47675cab9419f469901e76fbb421befb0f5285b03542000000000018199e78151f4b3af814e3d0b77e9e82ddfa4f3d44a8284b288051160a1016292c14100502152916028214000128250e0fe70fc1d78fcbf1f29ceaf60f3b7dda11df7587a941606a800000000000c09cf6c098fa59d7c8a71e85bbf674aaeebc7f40082ca000229161529015290148541402150500854a0021412ca004a75d5db1608f349d54c1e7efb7425bedb115242c0551000000000018139ed8171f4b3af714e3d0bd9ff006baea89daec2509496509410a82ca0949652594250020a00042a0a010a0000960a4290e3ceacddb7746875d107b0df668a77ad62ea284fb5540000000000606e796126852a6b78534f44367fdaebaba768b042809425042a02c28082808280010a0941016512c280000940128789e58eaa1b6dd86f5d4374fac4db46224e359b124597a68b0000000000330f11775f134ed8cdfc3395542f77c07dfca4b2804b05008521602812840a854a45005fcd852140214854a0004b2800003d1fbba75f8f6dbf1c46c8c3d5aff6e12c68b434a7608c63e49dfe29e53f96f4fae5e8f66cf4e5cd077b78aa72df2b533b009520ee661bec5800e44c5ccc94d927a2f7d4a7d211357ddedfcd0094259410a010a8280949650940202c5042a5041412c280014fcd944a04165004a3f1ab0da97f0d9f49eb35c75b8ec27b394bb0df0c372bc09d26cda7e6c1f9ce299cf539b30ca7f3a5d808259818721e3667cfedff00f3cbb54ef309164e565094000128000944582842801280011401284580a4a85008504b2801284e2fcac1e51fe781188b2742bb20e00c164c35f37e5e5ea4f6955e6dafd0e3c643b5cdbf4f1c17bfbe3d9aeb76915b47f83dfa2cd7a3601f4bcd8fadafa4dacf396a120601e77fbb42764618a781da7d663c60efacb3b4af79df5fa10c9d8f65ada9317f23a259ebd897a9efa5094008a12c2a0508a2280008a004a11410b2c2cb0a944a00965071f64627da620615711d8aa89cbfc42934d720cdeb807dd7c2b1f2f6a994ba06e53832cceeaae076444396179a1eb7d8eafbc549f3f5fa9f11c1dddeb5953f0faeac5d9560ccaac4889feaa8773af00f77e91c7cb98f9cfa51f2e2e9b37e5307738ab45cc17a3d9d288a1288b0a948b050965008a000004a004a250000960f4ba68c9dc17b3f4996269ae829160000001fd3e83e6dc191f57e9bd6be39032b0c000000001b3ad62fbed477ddefbe5fea294fa401c7ce0080a004a1284a00000815059412900a021413d0fbec3eef359d6e7a72f4798b61c9c6288a400000000002c0000000001b04cf9d26eec6a75eea48a276b2c2cb002a51016525940228016001280002500026aa36aba3099eb97ca0b434a0a2288000000b00000000000000006ecb49bb37876c1e630ab3784002280259400944a00b0042804290b2c2800038f748bb5cd51d9fa4f04d35cc0148b0000000000000000000000666e19737ea9bc6e3a2d22f4b04280828114965094000942288b0b2c2c02c2800030235f5965899737ce954dee315800580000000000000000000001ee7d338f977f1fd78fb90681faa7298f9896005045004b050450058000854a12800021a6be18fa7f97be9e5a8769d2960288000000000000000000000a406dcb22f0cb336917a521aa6f620284a4b2841528045000852165858a0001293d67b3f80c9c1d2248bfde5507efe580b054a400000000000002c000002ca25867cec1359bb32a7fe81046f310854a004a012ca01140814085025828012ca4e1de62e08eeb5ad3d0bdde60580000b000000000000b2900000000001953b54d4a6daea8dea08967a9605000020594000004290a8290b2802509c6bc94c9c2d024d85e065d7f373d38da34b016059480016000000000014800005948bce3d7f6bc9db3de3ee41a6fe86869f2112841400202ca00414094250944582ca012ca4583d1fbcbf7c58838adb6792144ba14f5dbe7e0494213d49b3ab8264489382decfd6ed9a2c1f7c60000000160016000a4720738ebdb5e275d96643c7d2bea5b28b61f63399f88397aa309ac9713b00214950a4140094008a042804290b2c2a5009605816512c160b03c5e29e60b9bd6e1e7126c7a6e11f6a378cf77d76bd13411fc77ddf13b269fa476e1be5bbad6f544d9f7acec3aad6a364fe67d7ceb32ed33e930bb1d475dcf7dbf4fb0691b91f72f75ddb7573cb19df356de71c398beb9a74844bd46c12ca0854a1050258541528216582ca0101404150161412ca2512c000a4580a402ca00025854a0020a00008a45859412804a0940859615280128944b28045000000004a004b29144b285810160b28000944a1280000000114000012a90a404a094000012801142585961404165858a25114400162901602ca0094402842804b2800041482a0b28944a1161408a4a0001144b292d8407ea0458594250960b2804b290028944a0960b28000960b288a000000085961404a000000102ca008a082ca000005800000001282582c1410165828009fa8251280850258500004a004a002c021fa80940000004b280102801016000a080a1000000284a080001400012801000016028205040284a1284a12820282001fffc400401000000503010604030504090500000000030405060701020811000910214050121320301415811623313435334160711718222425363842612832577080ffda0008010100010c01f7b5edfcbff6a7d3ace5ff00c91cbb1e9c74f572f769d93ebfc03af45af77e7e8e5d21b5e434fae87d64a81b06e96c8bc827111bb604700c59e6971adbeddb4f473ea7e9d1d3a59af38b18e03b8522fa938a08a329efb63975e2138561a0edb5f9bccf335f975f65f2d8890039667981e57dd7bba5571aa54414516ba8a2dd75695ad3f0aec94e671a10b43088e03a4ef67e66e5630efb6e6dcfce8b6d8df7c864db5afb017ea3203a0bc41be0f1b5f77849d22272a33cdb3df0cd90514372315d49eb043b6f3e8f287783c0b8c568c88a6ab55d726446f22c94c80bc74afb4d56ca156b5babe2babad78d965e257c21d95bab794361d3c421512da7a2359764e8717ad72c5ef95244398cfbe4fccbcbb5b27dbb4b76653e59d23b70bbbd86e524ac99d9b4e3a746ea75b6d8ede36ec77ae164d4dcccdec2eb7f8a6e3cc6c3261150c71c63235e64c8d70826c80db5f7528d892dc473074cb1308dccad4b0dc88f028860b4b17f181a565b79e602ab9874238c069db4b59f0330536a567f939383f25254c8920ffac74c9fee76db76cab29a938e95b5ded06aacd1cb1ae3a3d6977da4c716e1711ed845162ad2f331bbd9611859131e6508dbc6695516d384b863d6504c58c8e9a3962e735e08787f9e514e58a551349df445757a34eed2a4a6c585d8c7a459197824f4acd0ce690b2d1cf714ade2a53476264cda81a0c8902c20c345787a7d46d0d664d3571409b0cf6bb2d3e896d6442e481f62b4a569a57692b1963c7f5a21d2252890a325c38f68b0e794e14ff116d9bee05c6a2d95723655cc1050ddf9bc6d3320802f12cc068022f4f5d3b8bd9ead78e5a67df2f45804825e6de67bbb2da40a98a5c3116aecc36039a475eb1bed82351458860969c504ad1800a87157dc534b4e5a202a5ab9108c979d7178db4ad19d91f842194dd881f3c94781534c3829733bb8f3c40c926d5232928f061bdfb36bb6bb6befef49cd21a667c890647aad5ab5768f23f5f929cc0b69be06b7c6b1ab6e2f6ed882df2fcfdee5f8576c95c750d3ec1e446192d01d98cf77446eef4f7db295c520ab881938ddcaa86c9c82996865d4bd7af1d7b5cf061c2560f789a69544f9a56b5ad75ad79a4a5282e29808e9456e1ccc2b1326c4cd4b1343a5822874175b6df6d6cbe94ad326612a478b9474374b688fb6e412ae4fb5efd3a1504a24757a70d38e9c34e3f4e35db4f634f46454cc878fb0c2f4b2bd4b6fb312b0cdf99c2e971ad1470944022570d9858c4f4aa717760ae45ce89c0de4675238e80e14eb0d1458dd08d17a47466498565a51b84dceb905f62a4057c69755285c3db4f63e9c74f4e9ff001b69b7d3a4d3dedf3f3b8cace940c7241355a858971227622624914e562b40d416154eaeaa995a5117c663a3c2b7c5de3528f8d8dcb79045eb38b3982466d8f2df83022291d1a608c1064f6fddfdd7aae7c79fb1a7bc68d1724544386c6b430b1e4898cd6de41f6d5641b874ecc974dc911d166d802697f490bba6ace941196ea27843deb30e59286291f72932be350dcc72edee983d6a245035e21fd5cfdae7d369eee7a4877c6388af972803f963ee458deca00f7974c81fdacd05da9e90c8a15b76b671fa7b3f4e3f4f4d2b5b6bad3f12259365987ec4f5ab3cc2bbabdc4a510e6e1d8a5684f2eef7fe9ecfd3a992a4d61c3ecf34fe925cc5d252608cd6c71c8f5b1db316bf68614f7d03aee48c6a456b8026976e9e6858d7c314552f2bc22648295552695c17c5cba5c6152aa94288f5babadd2859fd0a6f6af8f07ee82e5d9ebed6fbb5036145ec74bb0c5f40305d5aa87976c052f987c2d9be5a5065c80da8e2e8fde298b4423dde6593114c7a8d18c7e610c825af66acece45a34e05656217998af2e9d075d25915fe58a8a53a29c25c2f11356d55b09d0c9d132f264befadd69c4fb28c5de6f95b1d21dadd6d38122d2b2c643bce73994acd0f82c441570eea5e1db7f71df81fe4360ed6dd7595f15975695a8c3541a17a8b7797c122fa86ac56fa7479c55ff000d6edbc695d2baec9d5f1278177b1a769df81fe436070d2ba78b4e5c133f522fd1e717e45b94f4257e965babe7c79fab9f1e7b73e3cf8f3e3bef0a8d7c6ac53d6875f2f0a9049b9f2b98682a29219e2bbdea248d21d371fb7a2e64272192e099fa897e3af419c5f946e7a127f4b2db73db9edcfd3cf8f3f473f679f41a7ab4e39171132e6e87d698cf9400d40bee4c6331569c0f57ca9a1023afefc5a7f8fc737714cfd48bf479c7f956e71fc764da689c0534f569c34ecbfcfd02596896543be9ad374f0d746d9712642c72be5dfbdcf1c4dca710959953dc4195bf825fea45fa3ce2fcab738e24e3b1dca29a8845251c4125da1076841da15bf875fcf8f3f779f07d89fd58b7c0117298fb84bde0baff005329078a5fea65ba3ce2fcab738ee87ff5904fd3cf873f7b9f5dbe761e36a6c26d4fc820dd4352dcd0527fdd64b7280435b718e095faa16e8f38bf26dcaf1dd0ff00eb209f7396e364098a345b8c1ce1f8893325370e3a45f33e15ca77540bf824feaa5ba3ce2a7f87b72bc774353feb1c9f74def58922b990c2c9f622678cef066a2a8b89d49e8a925ea28fe8e7ef66ca3281b6ba3ac972d75c070dcdccc5f58c9d38f2289e2553bebd073ea39d7db3e4092a9119354ca0660be65e2193c349c8848d460d8e58d60fc43ddc39051d9193237874899229d84d8e8c76b2ba5c5d1525a39d3650c1036291380d4317a1c5189111f6695575e482594128ceee0c26362dc30b0227d2b6eed8c23b2bad20625b46d15c730fb72d68c62cd22889ddd2448ed9d2bb2cfc7eff0043054525dec6c87dd3b30d5fb1f8a3af4798df94713651332d7546cb94a8f9711c5cd77bdaf1200684fa0244cca89c0881102e1468a5885e3862106a85e1a89c7f7f63e7ebd7db73365bef34136d675a316514e9ff007704c78e8f2acf3836e252d23dde66c9995a06217cb144ab5d7403448e07e7a72817340fa1daf66a31137e6ced5b049008f90b0d2e09e4947e140ee24a041480a1a4d3c0980bd8c428aae595bba49582dfdd7aae7c39f5f91b8458fd93805e6df8d3a165897376b652e33da6deb073e28e2464ccb57fb44c5126528faef310f2de1e56a52878f9c4eb89cdf111fb7c60486974a7f4b316ff00e4742db2c5e045d722814455d2e788ec90e05d6f98f8b4259344c56ae57cb6ddada19f51015418666745981185344ca5c50e7a62f8e562507680da4ab6b6d8da6ea534d08ab7110b5022bdf2fb2d12ca877db4ad32831ac9b78419d08e8609c415ac7286572ea883b24002f3986b1498bfc65cf2b81b570aa38afe0e459da768dd2e2b7bfd98473860703823b7d75c26a8450518d1d1b1721a7047040eb81d767906fd0d46a2ebd57406e3708dc39a87a2646899b16a492f08c73b053acd78192c01c2f7943605a20539e2c1e44bc675c6a56f304ab4badaf86ea695da6a8150e600c0397a85c41451f080a5a252e5f7e897dadac61875b7e112adca9f153d313520b509a52780582f4475183ba4e57a25b653eb75b12438d98951fe112acf3cefaf9fbff8edfcfb20a286007514612965b20e52c6ccba5e512cdfce4eb1f3156877a57edc92002472474a28950cf103360c0f09571b98d24d6f53043f962a3f71d64f615d78c3225ca052b4ad2ba569ea6db3dd0f039f00d741347848db0d4d0b786a726a9503b101b886d64b0d15bc960932bc2749cd262848a9429706616a39ccc1c2a589d25a47994693f1a0f927f1cd470163b6773d783be678cd8fe20d7dda5ad19e59ae15b4b8b30dab5baaf696e42906fad1cee51c507841d90cb5168f6a32b5043a88d67537de68e1af3694c3365787e3b3a2288e5e75a88e468123022c61b45a7eeade98754c8d4d60ea7dd5d4948635b4b3072dd7ef248e49d848ce0aea5555e2a23ecdec6286dbd7505a35fe3444f4d4f492d6924b220960786bb4e19308cc00c56eb48408f2cacacaa3854c65a5a3e21935b272928a41bb14128f8c58764e5d492dba5859c3682b25d9f9691638fc20ab991d2074b59495c2969f45532e6c0ec3fbbde3e7c9259410fa89c0800243cc46a21dd7a7b113eaaa3bd676941f75bc257738a117f530e477746eabf366a2a5c0d630cab643ced0d39d175a8ca160960b65040efa5d6edcbd87b48ecb8f48fc73ad7012db4b395ce778da222b2ac11253eb5ad6bad6bea4272b81b06e87dbab46890cc4cc67a22d6c28f64f0958bc7b2fb0e4d03c4d958b6a3f6c91e496dc60debd7dc263694a67784aaa15115cd54123ed3166691a3bada1b71c22d0b347361385a5a03e1a4205737f2121e71d2da147b9506f20ae94a81f9c98a65cc59c2ebedb29e2beea528b525c7cdea57e74f44c2f573e5ec568b6dd62354e2b0af6cbd919c56de55b80808c028a928ab9cbd4154f0c647f6489f3a96703504d362003c09943f3f1c166c8e62cb0debd457a271b812daa8469c4b46681159564c5994dd62b814eead80fbc18c2837f98089759700f17715a784aba9483a5cfc7c5f4d2f79aad7636b0aca1f9f54303f418b33608f24cfb08e637e253e3ff003d9b31a4dbce2983192518fbaec4d771aa345c251ca8c3780cb2dd49cf66b117525ddf73ed7e3d1fd3da74b809351ba79c8a177dcafad9f72ad9b702989e331b7d3b1616beee101518ece0dda3329dd54760956a9717417b243ceeb98f24a4b86a27842a575e74e9f5f5ebc3f0f5e5db9eab72bdc92189a85d961d7355e118a2af5e27884ecb7dd6d96d6fbaba51f2bd73a1e6a8e1baed7b3617383e3e3e3c817dfaddd87ebe895d73ecdc6ab8b36dfe1bbb36152efc23e94d06ebf4b7d5f5e3f5eb32e967e570f8c4adbf4af66c7159f924cc883dd7696f65cdf58f0954040b6eecede5511097c8ad855d2e045b0706d183bb5b7b26642b7c74a81275b77f67b3c50adf3d8cd0956b76b7751fcb8ebb57873e3af1c8654f9b4ccbc63c5ad3b3e2a2a7cc6154e0aebb5bbb23d947e6ef25655ad75ed1852a3e7305512eb5e87e9d1ad1ca27a39b3f5ae9b5f756fbab7dd5e7d9f078f6861c49b5afb9cbd7ff001ece9e8d3d12a9bf818c9c06e95d3b4e141bf2e4153255afb1cfacc8031f0d0d3804d7b4e1e98f265ef2f5e8f5f5ebed64cdf5b2115cd3b4e27897593510b6df635e3afb5cf8f3e3f4f66626d9876c62b482503f18d5a5695d2b4ed1868da30a3221a727955f236fa7afe9b7d3873f56bd1ce58aa6d6144777c6b687e6ad202db6cedc9abe9260998ecb1c63e48b230c18c5d2af2242358e1bf17b6436da0db5ad3b2aeb69bce72754f7122963a0bcb0e63f5badc61aa7cca38aeec52961b3e21882782ac029a42b2299a93584c30546ebb4d9a90f496f4adb56fb3ce081b3f0a1507f0987cba8302d65c1317b0fc0323360210c7e1da959091578b549ae249638139b1522070f8842a903260ae3c24580bc4234de85c7a3831ba636f56b70acf14d58a48eac8c37c3aba5982a274d4a56eae96d35aa045523b9f4f91b29446b5bd877292af844591d3d32c6de163248e82b9dc87942e6bc411a33bc37a03349042694ee2708115006a5cf930870d7202881c1ad4f31095972de17c72775bd15694c8dcb3846e8035b9bef52267657c579a12b5a84dc08e5aa9164928bafccd88aa15062c60b5fe59802f0eef6d35b0e559ae890de3c6b64ac7d995634f85609d0e88f86d291fd2e533a9646d45c214bb34b9c4fb1c5d90f14e1b46d2e1d0c73f7a1b0d94dad3e40d44f295fa6df4f67f7f65d7dc38989aa36796a09e00f6a8447172a6b53b1fa45d53b8d1099ead6b7b203b2a6b10e1b1f5f289a803b0f85d18095fb95b5a0f6bf099895fd9bb55a9b5309195fee782a6c16144756fed9ccb376c5f0e22607f6a61585d8a629c2657fef6d0c3548c090e277ec23e4fbb64e6533922b4aa535138b6d4b6db69a5b6e9fc03cfd7cfa0e7fc45f4dbebda75ec5f5f6f4f6f4e93f7f0fe5eef2f4fefeddcbf8679fb3afa39fbdaf68e7d9f9ff0008fd3d3cba2e5e8e5d934f7f97f0472ec1f5ee9fffc40053100002010103050a080a060805050000000102030400051112213141611322325051718191a1b1061014404252629220233343637282a2b2c11524305393d216347383a3c2c3d144546090b3074575e3f0ffda00080101000d3f01ff00bba7d3542af79b7b35687f3b1f491b11ff0043c5a6e7ba7f5aaac7d5658f1119fae56df3578784d56589fee21230fe259b453dc34515364f3385dd3efd9f85fa42fb9e6c7de636f68e3e21a1e96a9e33f74d93830d5de8f5510fb13652f6587ca3cd49e4950dccf0e083f866cf803255c7e55498ff006b10ca1cec805a5f93acbb6ad268cecc549cfb3fe8145def83d7448ad246df4cfc18473e2dc8a6d2e205cbe0fc8d165a724b37ca4bb46214faa2c749f81c805b94a1f8208ca9282a4a890723af0641b181163820f0a2e58337d69a9c76b47ee5aad72a0ada09c488db311a0f2839c71ed0c265abadac94247120d649b678ea7c2320a56d68fa2d74e9b7e50fb19c5a462ceeed896274927c4fc1869a22c79f60db63c2a6a387cb6a4740658bfc4e8b0d325fd7eb45113b22a558c81b0c8d65e0cc9e0c4734bfc49f2d8f5d8688e92e5a5403aa3b7235db4c7fd3b1e12de9e0b524b8ff008766d13f83b2d45dccbb42c726e7d6963c0a2bf624ac871feda211b28fee98d97ff71bb1f768b0e53a193edaaf8e4706bee9a9c5e92b579248f1fbc3061a88b410e557783b55302cd8699206cdbaa7de5d63413c7577c79534d26963a91174bbb1cc1469b514f8dd370249c2e49a7c3872762e81ac9b4ad931c51216663c800b1df2dd94edf1adf5dbd1e619f68b0d2214cedb58e963b4fec9b38aaa24c11cfb71e83d181db666c20afa7df43274ea3b0f8a8a612d256524a52485c6865619c1b451e4d255e0121be401a546849b0d29a1b4afaa38e2eba669eb6ae63bd8d0779d400ce49005aec9596e0b98b681a377970cc6561ee8de8d64d9b3cb23664857d663a859d30a8bca54cfcc83d05ed3aff6b32e4cb0cc994ac3683618b5450f0a4a51ca3d64ed1b74f8a9e55929ea2090abc6ea710ca467041d76ba29b1dd4e0a2f7817e7947ef07a6a3eb0cc485e37f07aa88bc2781f7b79d72e6271d71c6710ba8b62d9f7b859f7d34cc3790c7addb677db31aaaa71bf9dfd63f90d5e619def3bbe25f93e595072728d5a7478aebaa5a8a2aa88e7471de0e820e620906d17ead7fdda8dfd52ac019407b0dc253c870d20f1b47e0bd7b5dc61e1eee29df23276e561878aa6511c3120cecc740b5400f78d501c37f547b23575ebf31233836bc24e028cd4b2e9c8faa748e91abc5fa368d27f50d4ee8e53a72374ebe36baa889a6a6638794d436f628bed3951b062755a85b76acbc5aeecb89aa6672c218e352a066ca39b3280a30ce2d4d0615778bd28821a77618e4451e531c7274b163a70c067c7ccaa1326685f58e8ce0ed169aed92a2ecb82f2a08e42d50a0feae67565c37c0ae5646db5f923d65d3baa64b25744984b09d7be8d31c0e8317b5c6d77a0bd6fa8e33c2a890158233b5532db0fa55e4b4777b5ebe106a2f59228631fd9de443ea5aae769667e566389f34c3cb28c13ccb20fc27aed7ed525fb764a8b82c55f1c80ce9d2f93211f4d85afcbae2ab8d32b1dccb2efa33b55b153b471a4285e476399540c49b497fcd7e552483109454c7e2233b33411f4daf5ad01c72c51ef8fdec8f35158b1541fa37de3761c7a2de0854a5e94ec067dc7813af364365ff762de0b5ebbb51a93a296a716c0734ab29fb638d25b9cd0533039c3d4b0a7046d1ba63d162f4f74514b868c3e3a61db0755a82ed048e4791893d817cd755bc21f07b71ad5e559a1c971f78daf3a4afb9eaa33a3ca29db751d3f10e3ed7195181bbd5d493a4e8550312cc7528049b53c6643775651c94f2c918d2e824032c72e19c6bc2d7bf85916e83d68a286573f7f73b5f979d6d7cbb7e38c2bf7615b453a423ec46abde0f9b41bb427eccad8766163ff00a894559230fddd6ee5249d93bf194d7f54c92441b3332420293cd96dd765f082359a6dd72008d8157c4fab924e3b2cd577b34b557557475116e882957272909188ca39ad72510a7a606e912c8f9c92cecec739249cd85ab2769676177200589c4e61a2d5932c42a69e1c878589c013a8af2fff008799d549b950d3b9c14b618966d83f316f5568466ebb2cad2049ae68dce274e7b29a4150f774263490c18057c92c706c1468cd9ac463c63fa5eb7ff1476e516562ca995981386270e81d5e315087ef0f33ddea7ba3f80615eee31fd2f5bff8a3f172f8f775eff33dd6a7ba3f81e4e9ddc631df9548cf86605a15207dd3d56a9f08225aaa49a11224b1672e194e62b938e3b2d34179cd353ddd4e1049216a6df3729c3019f50f1eeebdfe67ba54f747f03c9d3b8718bd1c9352ab66686a1118c72230ceac0f791a0916b8d68a2bb2b65ce69a29c4e24c81a013b9e195a70c468271f23bcff15378f775eff33dd2a7ba3f81b8af7718b0c08b0a5a850ade93d1d66e78754ac7a2de025354c9514534448aa8666881c961c160506c389d1878f774eff33dd2a7ba3f1cb0bd4d555c91172b0c78170a0696c34639aca301c65e15d7c52963995a3af88c0ec760a8ca6fb36fd09feaa78f774eff0033dd2a7ba3f1ff0047ebbf0af19f8395de4378cd170960988689c9d41255c39e6b577828a979aafcdd5c72a24cbb37ea48d8478fca13bfccf74a9ee8fc7fd1faefc2bc677dddd252cc70cf1961bd907b4ad830daa2d554ee6ec0dc15af8a48c305f666854303ec2fade3f284eff33ddaa7ba3f1ff47ebbf0af1a5d502d3f8550c2b9e5a51f2753b4c7c16f6083a13c751568a8839f4f30d3e67475722d43a8e06585c9c7ddf1dcfe0eceb595793bc49256458d31f58e0c70e443c695113453c1320659118605483a4116bcef1cb86efa99a5448f1c4bd149246432103131be39c0f4b2585aad709236bdab375a59470a195777debaf273118820daf1a331ad7aab4b3291be5c2490b32ae505c4039f0b432149636d2ac0e04799474c68fc92b69c4914ed20df82ad98e0bf8ecc713b957d5a0ea594016db7a561ff005acaf97e4d430e4e5b7acc74bb6d389e35bce03155d2cc348d441f4581c08619c1008b5ef501251363b8d42639a0a8c3e4a7518e44a331d5e925a251fa4ee7a8216aa85cfa2e9c9c8e37a751d36be77d2648cc950385d6306f7bcc679047146833b3138016862caab917d399b3b9ebcdcc071cd74262aba2ac843c72a1d441d36a5632b5c54f3e3594cba4ac58e6aa8be8db16d5bfb21c887c208a95fc956a93303345c3a76c731d2b9db8162484a8a49d658df6ab2e2186d1f04b608d2624b9e45519dba2c7fe6d5a01d72002cdc192090329e91fb1a062977061f2936b7fb23b4ece3cc8c98bc21ba4886ad79329b0c251b1c36cc2d4e0cb3454cdb8d4aa72bd3be29261caa49d82cb999d11a9a4e7c96041e8c2c748aba32475c79563fbdaa11fe2c2dffcb43fcd6a5bb91627a4a8124618962d9d4e18e8ea1e2fde52d4321ecb0f42be1df61f5d703d78da90a8aca376cac9c74329d60e07abe113975753939a08b5b1fcb94da92211c483bcf293a49e3d23020ebb54be35347240245a463b0fa0757268e4b1f4a8e4787b1481d96f552a908ed4b7f6917f258d1c732c9538656fb1c7401c9e33f374b0339ecb5e2a891d1e562628c62716c359c746ac3e0d4360aa3428d6c4ea0396d360f785664e795f907228d43fdf8fe542b24722e2181d208b1c5ea2ec5cf241b53d65d9a46db0d38f8a953222ab58f2c3269c965c4639f6eb36c73a51d1053ef331eeb2fce5e33193eee65ecb2e88a9e208a3a07c1523ca2ae4cd1403958fe5a4da651e597848bbf94f20f557671e28c5998e000b2e6dc685be2c1db268eac6d53822ad2c671a4f6f1d2e397b390ca81e29636c55d4e820f8db3f96d2a0c243eda686e7cc76d974565dc0c830dabc25e9186df878e71044485e73a17a6da7f46d13e2c763c9abecf5da21bc8614c073ed3b7c7529faa5263f263f78fb366bebb68fd2340981e768ff0097aad86f9627dfa7d6539d7a78d974d2c0dbacbeeae2474dbd1aabc9b01ee2ff003589cd4919c8847d85cc7a7c6efbea7c77f4f8e968ff009741d969782f19d07908d4761f80da67dcb224f7d706edb1d0b1d42ba8f7d49edb724b7706ee716f66ebff00ecb6b104691f7e5597d3bc26693eef07b2c9c08608c228e81f0302ae41c62a43ed72b7b3d76a87cb9a695b12c7c519c526a790a32f31165ff981912e1f5d74f48363e8d6478c78fd75c7b70b37066a6983a9e91c6112e54934ce15547292745866f2a9314801d9e93f673d9bfe0e88ee5161c840cedf689f8670dda06cf14c391975f7d8e6c277f8890fb2fab99bacd9862a41d3fb22318e1c71924faa8339b36f5a6cafd6261ce380360cfb7e1fef29a6284f3e1a6c3319e30229c756f5ba873d82e3250cfbc993ecebe7188e2de0d3d3a70e77f5547e7aac8d8d35db0b7c5a6d3eb36d3d9fb307fa9547c643ee9e0f4616f4aa6ee7ca53f61b023acd8fcdd6e3011efe02deb4132b8ecf1f29361e83d62657bb8e361a3c9e0c84c7eb3e1d80d9b36543f19361f5db30e802d21c649a790bb37393fb289b2a29a172ac87941167c1292f3e0acc752bea0db741efe2aa484c92b9e41ab9f5586f28a972b7b047a873f29d67f6e3415385b923ae907e76db78c9fef6fa6999bbfcc2862c696791b3d4c23979597b474f155364cf79649e1487809d037df6872711d1cc248cf2f283b08cc79ed5b007031e01f494ed0711d1c51454cf33edc068e9d16aca869a56dac71e244fd72841e4cc245ebc93d278a2f6aaf8c18fcd47831fbc538963aa0953fd93ef5bb0e3d1c517551c7061ab2db7ec7ef01f6789a4a15499b9644de37de53c4c067b5657cb2afd52c70ecc389aefbc4b28e4491711f783f134376cbb99f6cae4af691c4f5b776e8072b46e3f276e26bc2ba183a01dd3fc9c4f3ced4efb77442a3b48e266926a871cc1557bdb89e8eae3987d9607f2b3a82a76712d15d71a11c8ccccfdc578a25baa1cb3ed0400f683c4a956211fdda2a7f978a29669e16fe2161d8c3896a6f29e5c79dc9e28a7bdb2c733c6bfca78920a6793a949b1389e28294d2a8fe203de38912e6a9c3f8678a65ba0b7bb2a7f37121a12bef305fcf8a65bae65ed53f971214847f8c9c52d4d500ff0cf124d42c6151e93aefd475af14ddd40ca5fe9243801d41b8966632555d4ec14336b68ce8cfea9e8e4b2e98aa62287b78998efaf0ad42ab87b234bf466db6072ea2a1f873c9ad8ff00b6ae263f3753087039b1d163a231f1d0f531cafbd61e9d049bec3ea3607ab1b0d3154c251ba8f10368a8963dce3f79f016f4a9aee4cb6f7db30ea364ff008bacf8d931e505b83d187159d31d4c0ae3b6cde9ddf3951eeb62bd42de8c55f018cfbcb958f50b0f9ca09166c7a06fbb2dea5442c87b479bf259b449e4c553de6c05bd212cfba38e84c476d86948144087f11edb2e89de3dd24f79f13c6474a4d18607a0d8e97a45301ff0c8b6a52eb2a0e8231edb6a15703c3f872ec3d2a4ac43d8c41ecb0d2fe42e57ac0c2c34abae07f69abc9e91dfb858ebaac987f1916d61ea19dba9570edb6b4a2a411f6b16eeb0f4ab6ad8f62e48ecb0f4a0a4456ebc31e3cf5668830edb1d628114f58163fb9aa953b9adf475c4fe206db2a223df1dbdadc8ff0096db123ff6b6c9221fe4b7b758a3b905b966af97f26161fbf8cc9f8f1b0d060a245ee1ff00771fffc4002910000202010304020203010101000000000001112131104151617181a12091b1f0c1e1f130d140ffda0008010100013f10c64adc5169b6589a59fc13542e889bd138637bb27f609276fe072ff095b12e3a12264c7f252369143e4981c2ff0009fd81391b9e4dc64fec68f8d2470b33f4492bf5099243e095c68ddd9304a6f7fa3a924985306da49370493b92b8f45649d13f64f27f4327f606d49234d2b25751d7f84a7cfd1b489492b62b726b026bafd6ab46b91445e9b6b2e238f865d946c270364e9db495b21c6da6289a81f4ff00a36e75933f16e7e69b5863bbd20c0e1afecc911a24f9d3b7c6dd69d87d0cdb1a4bfdd6071912246a3fe10a726df085c8d6f2b4ae47dfe11e3b9b930324b9ce8d5e75dfe13b1b7c7b7fc2744f6f8ccfc2a348d3afc1f7f92ba8f647437c12b8f635c894e1321470352e910f833846e35028dc8512d18db48ca66e438c093e08e47c113844411d0a592372b82b822b041be9dc87148c6514b2b495382b90e383151f66361c6c8ea6708ae08e0ab704378443594515b13bc193a411c1d49e57c54ec44674ce11961e924a994b46e748ebae4b5459d74f3a3cdfc55eff000b2f1ac3f86dff003ae4f3af2a4cff00cfcebbe7fe3e355dc8ebff001f065e07d89e57b36c7bd237d7a416de9350570670772f743c91d0ee847743d653a8f644f1f7aa69656bb98253c6ad41021cfeb1b9c2d17c6637f941b441e3e37f1d8c893643362e249538d2f6fc8e26b497105724aa36c95cebe470de49e84be746fa13d0cab656935124ed24f513f04be7e1b5fc2b7f8515f29f878d3b69428df47dbfe33f04e11db597ceb2372cf027c31b9db47c346fab48a9d2b8217228e44a5979e462c10f10437a291f6821e4862cd10470436448adc2654e4ad62a46a18d45c113657232e0ad2232c6a2a74a4b3e85c27df48eba56decadbd9b895c312a9d5d15c89263cc6e648629923867922e18d57f3a51dcdb4a3be98b45489a5c8e3097d9be207cafc89ec4f4295418a2b75ec8e04b6fe45c7dd8d7066c28c35ec9d92f63ec51084d3cfe471257054cc0f3434d64ec24d6323eafd905bdc9d990d90d691d7d91d46a05134c6e7fd26540ddc39fb25f2fec7dbd911917e4b7b8e70d125a6e408b1c49b44fb26150a7a7d930dc5335f91f72348852ff242fd628df464549052c8d4d0a38f64ae09e31dcadcad2b93c91d7e1445c49b1461d3ec2c4c95c9956c9a89147226b97037b48df5d2745136c71309ca1c48db796572573a44e4472c55bfd1e75f2743c9dd951d74ae7477727916d0cee6f925f249979221e4b9c8dbc365722a76b44ba9874c6a32fe8c69e47586674f2351b97c9e4ad98a332763b1beae996ec87046e6d93a724ce4b23497c92e452f0f24bc48dc8dd14b61b31dd16ec89d1387261d931850373913825b64cd2137b331b1505191b91b3c89b4a112e646e73238830b264999636cb25f266a46defb15236de595b12f3a5b7a24e698e7765ab25adcb814cc646f825f27614eda26d6097c8dbdc9d2f3267714cd12e66473b8fa8e7745cd48fa90f8660f1931fd92e651d4c6c6f2d64bda7a8bb3308b3621ee84a791d26071b22f822ad3e9477d22e06966fe8a12e86708bd84ccec4321eeb4ec743a8f4fc9c34dd3f00e537bc2fc2043c1e499e551d2097046ed7a37987a29608e9dc8e84edace9243e0b5c90dbb22f0fe8bdd7a1b9c930e8ee7630c511103e20953290dcee4a8ac9d849a5621ee98a7621ad8df1e06c6e51d053191ca30e8c9dc4a77d2075524f5138c79259d1f5fc8bb91cbf2791f26f91cf3ecb8c8b487c9e4c96df5ee294ffb306053991b4b727a3ea6297f8209d458fcdae181bea8cfb0ca66e179f2df7625cb156972963aba26b7b184b13e53194b934e5ae1a18e12eabc369e3e819f114ca8b932fa83f07c123eca013b1b7621f1d9a44d3126ed6b7487936c99dcb76c8fd9d22748bca23f6449c3722ba93a1d8eff009170df7bd32749167247515bc91d50fa32144ce96c87b10dec24f2bf22a74c7c0f96337c0fa23a90f8148fb1236494df126e2fd412f119dc8ac1dc5246e75815ec29986bed0f32912d0e5b918fbe911ba21f0781d646e0628c054f3852a8b948549a920b2a23b15034fac312c72dbf8756889bf474dc0cbdaf8b833893ce55fea61ba172ae71a4dad3bf62b790db4a6f790e1c4264a693503e86e47521f0257812b88d2e6117182dd16a89e965ccbfc0d6c2443316783aa478d618b2264be9f45a76bd19524cd6b0b93c90c8e085c91b22a0ca248af246ff00c8e1ba1294249dc8d24c4a4851324a88828c67e38206411b9152648563506c92b84965b6924db486c64f1a2dc5d9b8c4873659c2273d4b0b6db6db6ede8c0db807ca151bb425bb444545b74b38d2f36b7112ab6b2bbee5de55a12e4e1468c4b1eee102bc21ee8866a4d1863f0c5111d0ddf28c604b129cf713be8c5d0978439acd9aefe166774d24ed3f0b6d24c10f8d1aa1904ce39371293e5bb4e627d61025cae5b84b63405ac75328435a281471a4751a8794351a47c5f4217259dd99ceb1b8ede90fa7d97917039218fbc9d28cd3639dcb23a9636f7225db447544bcc98b917323ee4c1e4f2be8fdc13b8b251e46ff006086e2d1956241fa59804a367dd8ecd0a9b294d343d370ad6ddaf4ebc2d6c1b8481b6df0850e848f0662f4af7920f2a1642953b56e67a81bea26d60964b6e6473992498b6f496302934d5a7b8b4c0d0791a3aee56ed82e27e4b80a89c7b69d54abd1b137ef72c2907ba62bc5d1b6e421146d5103525232d527a4752d3ce8b04b624b82f0c96eabe86b63c96ab49ebe8c1813783cafa2e69afa25ebd7e1d53f4677192f2496351b911fe9f4752f0417b89b56295bfb25bdf1c8dbdc56a089e0c54698e0bcd12e0b17832b4c53446e5afa1beac7089a00db49c5a7a2ab194dbbb29d23d1e638152b0e3d1f6dc249b69108780a339bdd85d43a4b450ada1b4dd21e4f078f87817543aa9d39bed419755b47946dcabca73094817dd48286d24c4d234d349a12530cc4124d484abc47294804d606dcd92e71aa5d88976d7d9d4ec97d9dd12f0918d3a98cad64ceb0432248dbf92d59e0c92f764cb94cf24f2c5cc932ac4e192d6eceb24ce58d9ab626586265be8e361b6f3f09e593182672515be9236b2cb8705916d25472e8a27d13e612c84d4c584984b2cd256c9563a4ad7b6adb305252ddbadcec5634ad16aa0ad144dc8c6994129e534461fc35b90637afa1924e9c106d15ce654a74b4c9240d3686ee352c6cc836db434f4cad9c154b0cad897a36f122b7453cb132c364ce5b1b9b253298e397a2718d25ce46e77f427b489f51b976cc63f06d913bff00c25e646e72d8df51b927729657b1ddce92b7fc9d25fd8f8932a8be7d97226b744a54f1dc4dcccfb1cc99b9f66d7c8a5e59719f65f3ec973324b797ecb58fc8dbe452b7f7aab0e6f60cde17551730393cd9cb6ddb6482a5e35847979d8b7ea3e8a999b5a4def2614a32771e4ce5ee34d384d10cee439ca2dac91c320bc17234f95823a918172529a794f91c1daefccb7459c31b091c901272a92ecd2cdd259ca216d1e59d1baee3adfd8a7043fd629e7d978fe44f923b7d911fe8a9edf6437fe90d6fec8fd933a3b73fc91dbec87d3ec4ace8671f92d3fecdabf24b992e66bec68b6c44ba544958d424545a24f0748d1b15c0d408e57915396224eb7d893f054135104743c1d208e9dc87c09b823648c8d705b6e1d925f7b635930312aa1f1006f22f4c00976d733845124649a1cd2141dd0974222e075b10d6c24de110d6517383788208e1490f83c68bb17c1e0cec5d82c694c9a69b241a4d3134d269a189823316dda5a94d2a58e82c68584ca524932149488876886cbd91c8ba2f6632892087ba1a538d8621f043c8d8867821c606ae91212570384a0571a289b425d06d31ae863288e59170d91d4823a8d691d46bae8fb894ee750d464745414468f6bd36ce9e47db474cec0e238ae4e54cd90dfd5cd26d93dda2e541ee359b8cdc5dda5bf928dc7f1eda6f9177d17722e6cadc49bdb263ce87f1778ebcdc285a944ad8069b042622bd82e6c2fcec91c323a9b68a261fe4a1292b93279d191d758ea8dc8d3392a34ac491a35704650299844b7a21a781a6b62f08879814ba434d0d35944a26049e48b89d21ac9b19dce84325f2be896791773a102e2fcc4c3d9249b652d13489aef2edf5c39191e370d05ef7b8a55e9925bad1b9b6f496ddeb2d18c898db32608d3c92f72e84890b28fa26f720a932adbabb9b4f65bbe21da1759d75a9eccdc143e48626d16ec56ecc10cb1e869a7105cc31a738d25f067453c10f83a04dec34d6748a9129c10e60869590f1fc10e7045112e97b2368389478463642956a3ec772e0d8b176138730493b3c0df4439220d8f044650d3e0ea63284e363ab2945f574b447e9bec28fb69ac88e7f5945bcc3401fc11d04ae6099c089c2338452ca29ba454cc1e075b1dd0aea5dcf046f02990ef621ce0f050aaf691cb270d75127a6a24f0bb134f71981bca11c643d8d3eee498db7d175465617d902856d18db6e74ca883c0e38d37c0bb6a5da4f0676f645897ec8b383a45e8d07d89e747049226b74324a8d27626e44fa0f37a26b81465eb8c94568d95f42248536ca64a926377370e1246952a0ed168963e8c777839d6cfe0629282436967cc92f1903384c90234ae4ad68a994fe131724f5679f828dc9539d1729fd0f26832de1229f70a7ec94136b3d9a4fc93b931c6c28628dc87a4ebe4a2b594b12369b9828ad3b0b57dcad8a8266a0ce8f6266d892dd99a1c4fe0a257036b626143134b288650926a5b13aa3a12cec40e727666c34f2984b22c368a4f69f23e127b83927493232712734250b9309cc98a9e52a5722bb59e152703b2097819cfc9a662a125e16060620caa449b94d421349ca6e25d64da3e0a32d9823a88837a6b4c689b5866055a3d65d8104995c71295b68952da7a20db4cd742937f64ed1a08d3b2e25609e81e7e364455c96c25817974b48eaa47170236171a2c43257038d99da08570c8b6a451beae08de513fb03279266b451237a571ec8d9fe48b8223252863ec429a21febd2304704221722892229fe48e0d8c6511fb3a7821f0451035685a684d490e1a86be86afb72d1c88c13696def0e16ae0e1ae7d530f1a43cb5a6361291a6b63b8fb69d911b97be9e34df462e73235a2d36723186e67c48fd912da08d854cec43dd32b74c9703443c10429fc91bafc91d08594991ca645ebb689729c10dda45ee875438e4ad22f9d31b9446d2572351b8d2d84a4506f6a48647ec95c7b1c0e86b8457520a13415ad59a4da50a6d67f2bef5fd0f13295bc695b94518b4c9bb6389a2b93c95bfc156b43fc26bcba73f823a2b9d1349e3d8e36125c9d98e272429a7f26a3717715910f2570fec711428dc85c8d28a65418cfe449bc09b6ec73b964c33b89b54997c92e645310853347014ce7263289ca58de0d99cb25a54369991f72d16b21fd92d6e3e453eb109ecda7aeee08d34fa2a38e12269a839a17f1d835372b8886ce10942496bfa9e239849f0609664bdc96fe16a9e969de971a4b4c76cb45e07afe1acd2dbc04f9489ec29c8b96270a8b7646e4702e4b212e192f914e1496acf22592f91c996438c1d8c21cee5b61ccd8e8530442b1a8a21c48d356221ee6c7721ad88795b112cbc7e0b65312734869a466da190e260971a438943efdc2db83133d34ed312c1d990073fc1d1de107434908f949faffdf5fd0f11631f0f1ff2eebe1b3d552924b763b6e7e391caf44d6589751a69e9256c89c492594c8730d1690d389208d2dec470990f81094d0d34a4879811d08bc381a8fb1b9d84d4e3d8dc9e092b8134ae3491c6cc6d8a37450e246e6e3c8b91c3dbd99e83e55793b86f86250a53125bfd89fed5add350d0c7744ec1cb7719d18cbbe4e0a81ba934d17324e892bfd23aaeba288ce991c6dff2a23acb40066c88695a1194b2c6114e4e128256c4ae04b74c5986c52dd109aea52dc5dc9b96543660aee2c412f91381d61929e3f23207772672ca4f9190f449a75f812698d3777f43a897e85312a7a50d37bb9ec28627e896dc92e0b781abb6249b6a4969c7d111bfa25dc604f89f034d281ccc2dcbe072dcc17bbec298c9674f612fd810d99eb80dc5b9f4b37aad7feeb8fc7c8bb9be4bdb5b783ac98d3ce8a5ec475f875bc2745c1177e487fa881431245d165024f369f625c40a7645bc18a7f82dbe486b2b45d1fa15377a44f8e829d9184298ec43aaf425fb05bffd2f118e85ac3146e25d48513a6d267471b2146fa38d88f661c99fb2954fd692a29ee372c71b19c8ddc36c51c1c409a599182b682134cd851687af95af2d914797f7d5655fa44f1a6323d6a3551f15db5cd40bf0da7ab10514b7675265937453b7f928776fd15b4e0ec6f66c5753b63456ec591ccff656e38db450654b7636a37d266bf82f27ee09964a8b7e897d3e8c64a44fec0d9d856c6c97baf44f2fd0a26c7cac7627afad1b5b3f4369bcfa2b09fa27f605fb424ea6957901d93db303296aae7247da39d57aff0069c7fe1dbe7b9db5f1175e4770f270cce593fb04be3d13fb04fec13fb04a8b7e89fd813fd836a1cee37c7e0ae7d1b93733e899cbf44d67d09c7f837fb04d75ec4f6fa13fd8267fc1b594fd13fb046f25bc48d359639e46dbdcb5626f93c99844b9c8d3937c936c4deefecc6e46d23c6497cea938d13eb1d85dc77bd0f43202d640ad8735b9286bd5666bd6f6b6d18426cf649bd8d9692f9d2745ee6f66f9d64bd25cc965eda31f37869e73826d94e25a5bad5b25f4dc0950a5949d896ac4b92451c8d29ce9d6748e371a8d3b325f25ec409be4e8d2c84e978a1a85246e28dd8c6bfa23a92dd2126de46f2a497c924ef3e84dcccfa2d51d47d98f2e4bd84a77ec37b0f718a62647cc9996f24cbb628597f43876b722a57246969c0fa9620c4ec9834d3a69b44ae1311988ab8e194cf421166a24e7131a4da9a6c34304d7e99264d32659131592d886261729a6bc7c1f63c1e0a93195f1cec4ae34ee7812251d6ea4696c34d6ce0783fa129b73488e892489f73e3d5371b6a4c9ab524ef38924dec492984899b7a26e55894ee2a792db2a213278925e1930f3dc970e46dc773060f227036e657a14ba922ec6ae9e0777277172875498d343ee7630ccd8f08db2778d3c1b1d07cd783722e0ea62d1f43c60733fde9972d8e51d6511b50bb491fb3a55b10032d35a26c4d0269333ef5f04d7569e402b5a34d68c99a33b09b6dda772176245003ed940a8be2a397d1a2cfc2b6ff877d66d85b17915bb6da5e445a8988cc3ba942761b1d5a10f32c51913066d7e489b9111264b8d8e84b326190c6a373c0bf649cc60c99d8ec3bb22ec81f72f0d8d3c509b54c987324b870cc92e2072d5cfd12e29933d0bddc09b6e396ec529c49733d44decf25aa5e684dac0d9a8925bc325e644db791bb13686d89f582d0ef725cd33273378e2e6937e8d26a1a44f24ac6ee5a6c250d6c4941db8be193c070c7731a8a48528f5c8269b524d2298d3568f3f058922982cc0b745c238175a284a49fa6914f0a52a74634fe1e74f3abe73a2bb5422729d09f6adc54c9d990781b7862a237643e0973a26dee4b5686ea664bca5d872d978f46f9136ac96d8a550a51fb820b1b711226f66282c32e218db6e4b428e115d0fa20db1a6db15b2146e8ded0e1e140b366f4523c09ec57f4385c31d31b5b2253d895c1b6051b8dbc19140b3843a70fc0d84ea8f508865309325dc227f60bf2d124cc193712acc7596a5bbeb345fbe8499f811d5c0bb8789c7d4c84c5ce087b029ce58d9bde3834515f34fd86e9b227a69a8fb12efab046cbb34dc4a558984d364d61bd7c1dc588d35255aefae13712e5ac8c86485966e2770db7b9c50e385a749227097d94850b7461d31649253d85116540ede0f2428a63ce09e85495c0a1bb489e86302c8e231a52715dceb2386a4ae075c13b9686dee86f82dd409dff44fec693dbe874f26499c931fe0f3fcc09751b8e3e863e837348db2892654344fec0ddc9762b744c6de878d1d89c99348f29adc68523d4d86a6a6768b3955b3eb98c763a7c4f78557699fb271a3e7292e402eed9525484f8eafe40a2ebe52b85d456b4a28c322cd4c946e16b6d2d7c91b04a47604b5b6c0f410d0925dc90d751b76ccc7f84b7c0cd8ecd10b93ce89f45f437d04dbe3e86c96f2f4c3a63e23037d09d3c8975227744689d610eb827b7d09f419d46f733824dc2636f0de9d913025261d96f039dc87b694f2e072dc7043dd8947783614a59dcb6cc534bc8ff8d84d4432787b1d8c549b447ac0b10909ecd8dbcdc0d273f64ca8172b082f430a69a94d3cc8ce2886f78d39f376a1878658844869f029e47af229b76ed844cda691a792604e7f644bc07d8790b91387d565f27d73da61292faf8410f62a37bc1cf0b3052c901900b486c5c2f0afab6dd96b91b859fb13950b73a99a1d657d09b52896a6291702cd8a249851b0a765e4758661e3ec72a5343ac0d3c40b846d224fe8bb242721b5c156d1154853b0936e86b723df52397f6783aa20eff8d31942ad8f1a43e0c314b625705b5d84ab024de30431a72c69cc70521adc5888f278d84a7e8ec888c98c0cb944740a5b6dd243a6a0d177e56abceb81ccea641f34cd2c4c2e61268a1825e583509414d34e651e08bc0d7335ba97aba88f95b03cb1b695a6ea5832e0721c9e4d3869ac33b9e359e82b32514daef8ceac90a871afc711c1a974521d6254a7bb6ecdda5bcb6cc68fec992499292d5a573146ea15265870509dd4d27d5b2e860e823cc9b427762138d86d37302ccb5a60ac7b223284ac87381f4d2b73b9d511192b090d6f0781be08b8f867224f61caa212ca1adf91368b4ccce113b1b47f2775b726499d8822b2866e6f79ee295fe8db64ec5c457d8edc9644e5fb1d39fc89b56b44cac6d245ddfd08f86bfa04592a2873aa7cbf29d8954f507170317327d4ad24ac2bad6b0dc45cb6865a936da6dceeb1297ad73684d10f1a3e46276fc911f8c4e3b300cbb14e5f7f80666b6ccfb28472c0efe901462034bafbb34e5150a11df44a4895c0e714413b2298426225d52f64c3c961b2d6e4c9cf0928492a4924924b4979f1a5cb69afb200b89b83e84437579f253c7a7e148497553f9aa8872d09d12c86c52869cde8db1f613b2dd997232f26592fec54e98cce118b44b914cd3f65c4d1b1c410f9138762695b29c895c40b17e051b9da49974559a371bbb153b1a725442dcec84e071b8d29ad1b9d89bc227a0dacb4b7e58249d58f79ee5f2ea7d091ecc4b4bd36a66e30025bb6f3a3d702fb269354eedc6e87492e1a226befdc76c29f43308157a12648f0d359428930293893028dc518498e24ec2881a135ac76f917d4a50b76859c3694316dd0ee57d96d0c4f36dcb6ddb7a60c61e89c311cd44a70b69143a3943cec24c1e69e06c7b8598aec49ef2ce8b97a85366f6b492614347815ba47729e10fae9e070f0565e95b19b63c44122ad87067fa18d2c2644b891a4a7ff00484f041045c3687c959818e36129dc8ea440d47fa2498f891a6aa3c910cce071f43a9a96dba71e531f6da92d937fc8d2f6e85f73849465c8d4533a1e0c7c33b692a513be5ba5baddbb752a799237396d43b16521ad61c4ab3c36233094a7479762813dd0f28a52e02431f38baf1466f085af0695ceea951d41266644c9d48f23cb9247af3d72db6fef587aa538f82a0fd05b8609a7d50d6c332499d26a1ac25865349d85275fe15b97c11382144b7e0a6dd91d5510def82277225671a2b6472637d37ee388ad171242e494c71b1bdfe052de0f0f07528b4b1e855fe1863c1943be9a4f23b70851d0c24e0b89276fe346ee27e8cf095682916ece116eda5b8fff002ed9174ac36cfa049250992a6608505704a638276f8ed122a3a215b241d97942bac9520afa31e9f0c99bbecdafd9924bf876f82f8a6d394e1ac33726a0442867c24de589db4c2704f02982f030fb0dc519a479f5a76129a4c49bc89c6516b2bd13dbe89e63e896ae3d0ac76b4b4b614ec5ccd92f324b2e249696497965adc53c8e791b69e704b9a62cc7a25cd3ec43dd10a264b8b634a5d8f3438d90f1b1334a12d8d9f2586f74672f4f3a24b92270c7dfe1e7e17ffc8d53336e20fba908dd3224e4eec9e1e89b7ab18b42c13591d611e49dac6fae8e53b6e4bd996d291dc59dcef6773c94b246e9515b15192e2a473382e2234a8bfc09f3c11d0b21e20c2b1dccd1bf028fd466ff00812643c4321cefa40c93130d5ed2f5684ead0e26cab98c97453096c925a4374862a0be0c6c350a4da49e9f1f1a3edf3a31703bd73f071b1e345d74723798e1da4e8992baa5706d4372b0299e4ea386e4678d26322adbd0d747f46c761e8a729b1c6069222702a1387836d23f674a7d08edf66c42e47261910f3ecafd653b164f054d8d597e0b559c67cf8a9e9d48d36c6e4564c58f5aff008aeff1adb5a1b4b2fe32b13a50d32e74c2dcf986f720854c94d5393c9dc8967833b243d5db15395a6f4761e903c10a63db1a72399b624f61ef65b764b6a1bc90dd58b348965acfe069a24ce8d961a7f64f027c21f7f443730c75b907c015cc0f321ad12de5e8addbd6e07dcf3f18713ffc91f09a35539721afbb1e487130297e0cb21b5d869e073beabf68b5507621ad8b9bf236d8a7614a70e8b489636de454f0294e47d17b216ff9146e88afec5dbd9dbf25463d8e1e17b1cb646dfc9b0d2ccfb36882629985fd8dc28812cdb366f0b76453af2f66cbd941e0c6c56c270f164cdc15c596f63c0d3e34a8d3b68e78812e923edf1eff001ceda3d57c6a746d9ec78c47daf2567f2c99b8256c3e12ee65ff0064afe897bba2f02e9f92229f1c89c60973324bb92631a28dc6dc8db64b4a98a1acfa26f3e6072a67f07544d7f44b8afc12b67e8696cfd0a30d9292fe87d1fa1644effa29bb64254c544c8e3f50da9fc1528b5b869a090b92b571b1054146df2f3a3eff00f0f3a677d7cebe745c49e4b9ce8c8cc655423cfa8672cf252c3f43aa4649bfe899cfa0e363c94dd88589277fe044f6fa13332db1c73e8c394fd0f9915bfec9966299d4db3ec6d6c84f7725e248e17d32791e4cba1b58dbb8a330373fe8a32cee4a4ffb2b414876d86fdf2630c6e77d3ace8f2270388a67925c44eb2ffe53a2efadff00cf2e3a1d40dfb684aa50c94b050faa1ca74533ac16b62e6bf3a27ce99bd2a095b50e361d5416a852b7279661d1b4ff00060b7b10f105ed26345334429dcc9b10f62d2c8edd8a955aade269e7d4c69ef247421bb2088d8878f8be74f1a748d7277ffe0edf071363d726a1dc0986ca53223261d9696478f85bca2f2a48625242e761e2744a771d5109730344cec853348753289e85c41b8b38d3618dbdc5d849cd21e64da5213797f63b52d791a9965fccb9c84ff5515b22b457443988d21f06d3a547c1e4a8c8b4ad898cff00cab6f956cfe09ee98fb2e36e463144bdf72371d3c6982e05d89e0b74869e3d10f81cb548db22c8ea98e70c72cb4faf5136b2d8db78922e2c52acca997f4777a3b0db8cee4b912e6ca9b16cb236b25ecc50ff00c18df0f233c1c9482fb6263757aef91b6edbd7c93d4ebad7fdfceafbe9d3e6d9a094e2167850995fd136373226d38666d9dd1dc59154d7a2630297b89bea4c517b48a9da25b56896fc1b0af64527823a236885f656e8ae051c15c1438d91e0cd243c92b8268f236da81bac986124a652ef4cdad693d0b785a509a5b12386b043cc0c5746c77d5d1e0b6454ff00c68df5c67e09549143503a536cbb08d2fbfb995fd95238548b83c14564f03b7f8170ceb44f3a2c9349181b4ec26d0e115b8a39f44fec10a34986e7f0560ae7d146ff00d1d0e8429c90b9f428dd9246dcd9f1ff00904de1a6756c98bf46c513723ce89c5a6564731a3129a3a9d48713aedadc117674d119e0f3a3c6b1aaab8265c8a60d87891d47f10c36022ec849c37e869279dc6d4d1821464c6e475296fe88514ca5a3abd336428a6349618d10e44438925aa93c8938992e46a0892f124a6069cc0d34c49b74369b219959d1d301864f0dad7b68b21c499a3243ceaa76d1a83ce9d4965e7e0fe17f38a9f8e5d69026f91e3258d831255cb43f0c43635660b8c992c8694a7b8d33bf365e67d96885bb2173b510b371a25ce069c74e487923aa14e60f04743c1354c8144e079c8dca30493b3582e696e3ccc7d9b6950315c2d74250e2e0d8a1f4d3b95143496c263b2604c7fb074146e35d4978d55393b0dce8b3826968dad8a8d27471b6b454151a6d328f9cc0eede0c3b462c705707814e206e46f6489e49716252f381c0a04ffa1d2c0ed513ca2596493b987429e7497c92d99316997930e512f324b991ccdbd27a68de5ca7667bce93b1db5db24e9b422a07aa6d527a4fcba493a2704bd8eda373f392b4978144576dcff9489cb6e0969e771b6ee4c7fa5e64509ff66097eb26304bc496a4ab83b13b9bd1324e2c6df2492e623c186c986592f6b2795b8ba0c6c5e513501f6258e5d937324f43b0dec5ba187903ad948f5685e4627934e1a6ad323549eb6f62069f028e4ad851bead6e50fb691f09d2fe1e051f182051964d468e822305409ddef8ea4f427761bba44b782e6204ea205d8be04f80b1f913c4928a898c123750940dcac791cbca25b51d511747830f929a18eb10cf06c38d87c90a69ee5270d15cc8e33056fa654129a2212e59c236b70296db5a0e29b8dbca48a5755299793c130783bad79866daa9cad22a7e50b923a9d247dc8d8f3a58fbe99d37b37b1558c8a129abec841043eb4ef874621d4991e6f295484943c612494892eae3692a6c7f83aa1c27cf7d3c8d46e62a485c9289cd18c3d2a069440e632c625346f0f6e84b55fc13275d21c917643e08ea6e35fd112e3034f1a2859d5a42da53b71cc0e5d543271e6d8b3b44f105c0ea6c5a9ebd532fa2f78f5cb51bc29eabbc68e0bcad3cfc9fc323adcdfe10f25467e352266e15f62278780f9533e1b63c7ea1cb2b86b4decbea500f34bf3813768492424bb21d0d5c6076f492748a221c3362cee8511f823a690e31e88ac913d344deed93dfeca8c32b8f654618a237135bb7f67865b55276d13d92dea4953698f35a575c13b29fb3b695330356448bca5f866ad0fa521b9e7b4a5d1037b60d345c56629753c247527fb20dcbe70d77e14c6fb09c0dce92c86f964d40bb7c94bd86e76d218dcaa5a373a5a171d63848a5b19bc397ff008bda4f1986dd6e896f951ec413e72934a9eca36d8e6d7cd4f86245255b4109f253e4dae471b0e5b30ea471137660de5b25e2589bd996cc8aaccdb9146e632851b959498dd0e308b794c9e84cec5bb83798144cc0ab285563bd89ac226761f6831947530f1e347846c4ef08ded13099e0f1a4cd421aede0ec21bcfde321a6737aa239c97dc62f77e261b98a9a65e1da5bf80fb2a53fecc62659a8fbc9ec38be10cd4fb3d2cda67e4d357a2998484e796e2d1f7132e800f74ffa25944356fb34df41bccf15374535de1d84db54e9f77b7c84f0f613e3bac9e59317026f0fa189de3d0a1e3d8e9c28225e50b88f249df262ca4eaf9368664cac18d899d894f644ae04e5cb4a8493e8646855638f234a68db027b8c9850c7d3f2546b9a2e2073a3776492fa192b8d2344e302813a373f06c73b9df485b7e479705363784634cbe7d6899bb1922bb25af431699c5601d9a3d9003cafe13f028ab96d7089609f2e95bf71fa6ed652a64729ab6e5e94f42c53d8363ed219025b1d7948a0b22c24a1109bb3698d7a098b44de09da0e8589d0e49926f03c915fde9b1d0c09c3913bc1e0bd8bc089e50ded03e1af437236e3239c49794413b2c97c9d1124b8266d8b38fa379ea6f7686d1378147c110ce9248c9a8146e7621f0c69e59c244bebd07386ca724b5b90a6087982b6624e2479a64a664538445c09c6e396d98c90cbe4b62e8cc0b3ff00a74918853844ca2592f925e53f64ce5b2381bbb65b72896f7d2615691b7f1a50dbe496b7c93182c86656fe58db791f02b7837882a4f1a50e30bf22cd911b48dad915253a4859b5b8f3a748f84a9c1538a1c09f4d2497ce9c40deff0042ce24ae3d9e3d92a706c49d9959fe44b7687595d8e84ac35ec529c4fb15ec45e3d932b0571ef4de63d8fa99c0ba7e47fb7a2fdb25ee4ca981b9725ab81b45cc0e1b3625551dd0a4ca8fe4ec60798fe49a8fe495c0d3cbdcdc51b67a931716369ad0929130ff00a267fc13e7f06d927a09add7a3bfd1b5bed43ce7d0b237b275d04d4beac6e5e7d699448eee349dff0081c4e7d15cfa214db1b9a68ad1772525089956c5dc6e5cb64f5f453a64e8df6fad2672c9eb3dc9797f813533049b2b91bebe885cfa30e53f44cd0fa15be8bb9bc49359143cbf44e6c50f7c74d13d992f6fc11774429a637fb0493fb028e7d699cb337262cac89f24bc09935fc4132a27d0e1c487045ff62cc5fd8f12a7ec7777f625384fecae3d91786b81e2cb8c3fb2995ec7130d7b2b8f326f30445c7b219b4d94364dc99c2649ac7b22b1ecbdb46b8451e087131ec7184b18727129fd969dfe494ffd2775f91745eccbc1dbee48713fc89f4f64ae3d8df4f6744fd8a9e1f6335f90f331f6cb8883adfd931cfd8df0dfd8ef662a2ddf287333d4718fe45d567792a1d323610a612625350349657b128dbed8d3580d467ea4ae3d95c09312e3f23fdb2f293fb21ac2f6537b94d36e7ec49752b812de1909aa5ddb1c4d2d86a15af66f29144a8b47582b62b7fc0bf688b836ea351929e0ee78191d0f056e783b9d451b95a3e8878d373ba29332fe89478371f41e471b494f6195c0e22bf06f45492871765623d1592b2915ba1c6c57051438d85466bd9df4a75fc15ce92b23319289146e515b92b811122bd2863496f25705bb6412f326192da31fee9d49ad18db9b21a75b0db764be452f08879d5382d12f925e0873039c968cb14e10e77fc13c3eee052b035d74ee4bdbf036e25bd13a2f088208e026d3b1e5f72d16f2cc9026c42ea24db229126d849e086b62f6fc0e77304b4e590f2c8639999152a112f1436f1236c093d887c6086e8443c0e63f881b6f236d89cb8e8257123ce0b684dc447a2f721cc7f061dad24ec8578f24c3b7b8da9feb473c99d6d6de86dcde92f038436dd3d3625d0dbcb9147f4295653fc2f44998368443e088e8c52e99b8a53ad84f792e6453867f1d0b465db1b33b8a3106e5c0948a76f24b9cd8df05e50fc8e246e5d96c97192f6d2535038d86ea20ce3f029c225b76792c6dc4592e258e62d7a25ecc5138f64c3782a205c1b19a62696c6f677fc8f494df92526c6e4da0ac4e979d26724ae0ac40a37436f9138d2a3237508851f81477299e09d6375f9d23944c5a2d3a13b964bc8a1ab465e484d4c14ea086b23724c282b73687f9214b5a285b132e5ee27bf036e6d89b5687d8a9b1e606ea34ae062ce3d98ff48e4a8a292ac89b53d749689ea37361b5c0e310249bcfa164985fe095cfa324a8146e4ac3fc1856ca5bfa1c617e0a58e4ab25627d6929a254695b14f3446e62c7f5a3ea3a569b15bbf436a5c12a3fa30e9c924f3f8d144d91bec4289917ed09adc7fb426a6bd981a96c6b7fe08a2a267d68dadbf0495b8ad4c909e1fa2b66249ee52cf143876be894b62165e0696246a2a7d106e131a8a91c690a3224b33eb4abb5f4426a9fa2ad7f02886d8af256118434a27d0e0e9edc150ac71cfb3cfb15efeccbdfecc5a7ec5dfd9ddefc8926eff23559f63493a657eb3a7f25739ea3e23d90d7fa5bb2b8f63bd322fdb236fe74de7f91aa9fe49789277fe4cffa384e8855ff00a4557a64f5f6426f26d29fb32c733fd92f96289261e470ee7729e5fb1b4d8af0fed8d5bbf62bff004accfb31bfb1bfd9171657eb237fe48e7ea4daff00242fd624a27f92b76425fe8a223f921467d8a04af3244bcfb296fec9bb9fb15e44e39fb31cfd9ccfe497132feca5e7a9d5f914328acff234961fb1a4bfd3ab249e84ae099d8927a1977a4eda48e66c79c9d749ff0008a9f8ceda65c6910c4f429c21f0f59e8513d09ec4d133b225706f06d4b4997fc13d10f2c55699e0ae09e84f43c09ae099d13edf444369244321a70c8db474344add1b606d1b1dfec92537704f4227721dae06a1c690db81e6debfffc4002c110001040201030205040300000000000004020305060107401114300013101220333621313234157080ffda0008010201010800ff008812952958c62b3a867261097cf8ed434d0938f759a4d418c744b94da9b98e8a3b56d24dc67d4fe922596f2ec41a0991a4a872b9c28a41a42186285ad82ad3492cdfaad54f88b687ed1564ae4955e4d4199cdd494a446849992fc176a90d6e8750ea2187857d6cbbcbad44e672786070db6869bc211e1dc30c98db4f72df2f4c86926dd97b3e2de4161c8514ae6474b49c4399702d3f63979c08a68ff05ee54c84a99460b21639e9667d93399a23edc878769fe0a5f3b44fdb3fc3b4ff00052f9da27ed1fe1da7f8297ced14daf039cbcf8367b6b768c6611cdd2d6248922ec4bbe0dbd62c44d77b16f9a2164025209620770431c36152225b2b2727e662e57616bb06a2c48ede52285743ab3b1ab968230331f034c1a38459245c2cafdaa75c357ceaada4daac8fbed4447ebdb98582c7b9eb18b260d58848ed3f713558f7a9faa41acc820f7fd186891e328827626c376d2ef661f30408c3dec342c1e9fb3c9e70b2c0d49510e3d63bb70a4cad40bf95e8c9692862f048309bbc969386e546dbd497d3d56f6daa3349ea996de20b69ca636c36d9eb43df39f0d09276039220313a8eb434276874f694941b39722a520a6615cf90ee38a2927109607aae990986d244d811b1f16c6190fe058829c3a9822cba558794a7a1652916b87567b95214857457a8ead5825958c095fd2b264ab0e4bc1d7e22ba276e07c1d6597dbcb6ed9352572610a702b057656b321910ee2ea1a7b71d1b89827eb74619ff00b8d821359ea8faeeb551ad90ab194f32e8ef29a77875a8854f4f0e061a69b61a4b68e0ee0834c5da3ba6f87a4e3704d81e315c2dd51b82ab4d978e1e9107d9af3e567857907fc8d44d6789acc3eca901a73c279a43ed29b5963a8429c615c28317b285187e25e45ecee0737c2099ee0c6daf58c6318e98e1ed963d9bc919e15691876c41a33c4dcede1170c6784194e026364b759b7c2da444ba270a4a56361c6c906deac6dda6c6e9ad709b71c65785b70db4ee10f8c23315bc22dee89908dbf53e57a6196dc6dd46148f17edea46d95a8aebdd4a6e9ad09d521cc6e3b4c8632810d903a49fcbc5f1c492908f57cc283b36ec0f4c244ddf626bf4206dea22bfb0ceecaaaff9a3715295fbab7052938fd1ddd3516ff891bce2d3f60bde530bfeb1bb62ec675c24e9f9c93ebddffbe3ffc40040110002000205080609020407000000000001020311002131415104124061718191a122306282b1c110133242527292a2c214b3202353b23363708093d1f0ffda0008010201093f00ff00640264d0fe9e19b889b91f2d59bde33d5486d18e2ec7c1734719d32185bd01f10699041ff8d4780a64d98714661ca6579523e7cbdc7903b984813b42eda4328eb686123a7a967620002d24dd40226546bc426a5d78b7090b7f8964e3d971ed29f318a9ab61ae8b58ad5858cb711ffaa351d39671628e803eea1bf6b0e0bb4f5321156b86d81c0f65ac3b8da05049949046041911b8e99644700fcb6b1dca0d04801203003aa1258ea1bbc3a2dc6a2759d307f870d986d242f831eac56910aee6527f11a646686c4489524123032a45313d595cd2d5b49834c1369f66a9f5265114000e19cc167b40356ba652f1127393312278c8edd37fcafcfa9ec7ee2e9d8c3fcfa9ec7ee2e9d8c3fcfa9ec7ee2e9c2a261807580f3e131c47522664a770752780af4e3d18bd24f9c0ac7797fb7a93fccca3a3ac20f68efa9779c34e6cd742181c08331484d04d85802d0e7b4098c644558d32c847bea0f0241e54648b1261546702266f2019c80174aeac53245618a12a783674f88a3324522611c489956644120cb6ce55cbd2c15101249b80a54b620f85058369b4eb274f19f0daa74363ae1b45c6ed609072584df10cd0aca70602467aec37134c955638208912262f5accb5d78511608c5981e499dce548e62c559e6c866a824489b492644cab0357a1c22289924c80a4d72553b0b9179c00f746f35c80d321b446372824f014964e9daadb7283fdc5688623b891763d21ad40a964751371244e833a093d188054751f85b51dd3148a61b8bc7811611a8cc5327cfed43323bd4d44ec206aa4574d4c8df8e753282da823f9a81ce993331c6210a382924f15a4525458a2a41b171d66675d219773c00c58dc063e744f5915ab68809041c13051ae73b48b008c22afc2dd16d93f64ed39b4c9da19ed0201d86c3b8e90859d8c80159268d9ef6fab53251a99856c761036d212c35c1401e16ed3e940e8c244113077522e61fe9bccaf75ab23610768a648f217a8cf5e2b31c654123e8c95de778532fa8d4379a451097e159339d44fb2368ced9484116f37b1c58da4f85de950ca6d044c1dc683f4f1715f609d6960eecb7d124d6822b5618a9bc7316100e8cbfcd8a3a13f75311aded9fc32c4f5081b6807c690946c503cba800455ae1b60dff4d61e36814126524106e22a237689644600ea5b58ee504d04954000600540684249942e777854de4c75b6882a84921f33990fb436862b82e3e97a8f3cdd10571224b72a897363a1899f56586d5e90e6344b58163de624722343b1810761aa96a3153b8cb43f721a2f050344fea31faba5e7a17bcca3890345f7821fb14796857c5863ef1a2df090f361e5a17b48c186d5331e148833e5d2427a4a6f98b48d62a3a1c558682f632e1793a84cd0110e415276e6ade7699995d396864822c22a237d237ae4174419df754dccd3266867142187039a473a658809b98e61e0d29eea1041bc563accae1a9176702df4899e5486f18e32cc5e2dd2fb681602f646737d4d5705148ad11cdec493cf488cd0cf658af8114cacb0c1c2b73227ce9021becce53e2472a644c3e5707c557c690a2af754f83f951dc6d43e53a4473dc3448adb157cd8532376f99957c33a99222fcc59bc33691c431822a8e6413ce994c479dccec4709cbfd79fffc4002c110001040202000405040300000000000005020304060107084000111430101220333713152123327080ffda0008010301010800ff008814a4a13952ae9bfab35e71514597dfbb109ab3fa323645fa4abcd6d6c1bdb2af348cdddb2462b1e2a9c928725d4b1601a4c798868970bbd326451d1172a4ed2dc84ae2f2c78dfaa8bb04fd088e1f8550b787ba854111fdddf3b25c304555d81ec6b6becca0d813293125c79f15b92c76ee679359aacc27e1d75c7dd538e7b3c7cb12cc523d13bdbe4591544a1263a7dae3390535649b0bb8581053cd25a25c83a857eb2420be2fd8d5c087d92f9087ce1550ab0291ea07773941f7057b3a3bf27c0ef7283ee8af67477e4f81dee507dd15ece8efc9f03bdc9f75bcca16de3d8d28f36cecd1ea5f7791d5154e12c1f63d8d035151eb7e093bdd210221482ec39568e3ed886cc52044fa1dd462f2993aeb5aceb7599104816e32887139c8cba69fb7d2622a649f80e1f30ace6e1c4d7b4d8d46ac34391debd51c75e047a678f18db5aec8e47cbd75bacdc3b2a33652fc81d783919f4fb077a12b98970545f03c7ce2b311121ea3d48cd258fdc48f727931c2a3e5f9b66e4152c3614d8f2bbeafa44ab72d9d7bb281dfe0614c1b021ec70550c95938d315e714e8399a0764c55670db1a1f66bcbf2501e34147578598a9506af498ff0020bb1d942d5062a7933dbeae536c9ebc6d5b922166612d1d0969aed91afd419d79d3e18c86b952ef3c89232dd5c5ad933054d49cc89ff0833e68c96893129dc8f9715098d6209b3689604e3311b71b753f32339c631e792d73a9824e733ed7c900d110a640592d47adb3f32ca7c187df8cee1d669dbe6df5e712d10a9dbc1dd056278ceaefdd82f18339afc3fad9972e37da748907f1e4efd7ae6f13289636e6a23496264644867a7733e8abd5a59453cf3b21e53aef478fb6551aa57a177a7c9333989548c393d2e3899cc2b9bb015d3e4a13cc9b746858e96b4279117e1d27a9b908fee5b2482fa6c3cb8efa5d40f9689f01a928e95926e4958a64bcf4f584dc90d7c31ecf449c8f4835f7fc6739ce7cf3d3d0f2732359c54e7a373732cd3c8af1d4e39bb95ebf527a44a0b24c7bd0ddb950ac5499ea627f483832e7e62628ed614f7a91506473fd27996643596ddb168ed7e7f395a0e71a4ec7ce5628c6aebf83ce7325d69d6179439ed6319ce7cbc09a2dc4ee71e84271cae93f38510af71e6922b387278d122c346c4781d7201841647c9349696d6c4fcf2a9fc6aa9bd9ce624ce31104e73e92471baf2d67fa9ce3eec7467f8471ff0064ab3fcb1c72bfbbfe7138c87579c7aa83c6502de7199837446b61fe5950ca9d602f97a1ff007c7fffc4004311000201010308060606080700000000000102031100122104314041516171811322427291a10530325282b110236292a2c1142063a3b2b3c3f0334353708093c2ffda0008010301093f00ff00840680597f4b986048348c1efe37be1047da1695205d91a0f9bde3e045bd273f29197c94816f4a4fff006b9f9b5b2ce940d522ab579d037e2b64dd157fcc8ea547790d580de0b1dd6956489b10ca6a0f8798ce35e9ee1234059989a0006726cc62c881a6c6977bec5d89cdaa701facf7a263d7889ea38fc9b630c46ba8a82d81c194fb48dad586dd8731188d39888216fad23b720ecf750f8b63d907d4d5a07a2ca83b4bb46abcb9d798ad09b35e4701948cc41150798d333c484af78e0839b102c6acc4924e724e727d51abe4ae53e06eb27855946e5d30ff008d2a29e0a19fe6a3d59c24883f34603e4e74cc9d26553501d43007354541c6968043d32c8195705aa14a103303d6c6981a0d75afa85bd13162c2b4a85467a1a63425403bad91450c94a5e44553434a8a815a1a0d3764dfd2f53fb4fe53e9db26fe97a9fda7f29f4ed937f4bd4fed3f94fa7117809491ac0263a1e06869c0fa93404b8c76989c01cc9006fd396ad07524ee31ea9f858d3e3ddea57ea724eb6e321c1072c5be11b74e5bd1c8a5581d608a1b4c994838842c125bbdd6374819aa1b13a866b7a3a65dfd1b11e2010791b24904215999ae106829d552c28092467ae153436cbdd0ec9155c78adc23c0d956480100bc66a054d05e040615385684570ae23e942f24842aa8ce49fef90c6d4327b5237bce739e03055dc06bae9e4c72a631483da46da33120f68571dc40232d9929ec92ece8c36a16a823760466201b65aef92b2b29aa82158d2eb10ab78814a615cf5a5a47ca1b622103c5ee0f0adb261040f4bc4b5e7600820568028a815a0275573fd1199247345551524f0fee9aec03e5ae388881ceaa75b1ed30e030a96d3265890769d828f1245af65520f77aa95deec3f855ad22c31c6d511a8ea9dce4f598119f1035800d0d8dcca1475e227ac37afbcbbc66cc403681658cea6198ed07383bc1077db2bb95ec4a2a393ae2071563bed024a36ac8a3f8ca9f2b648a9bccb1d3c989f2b658a8bad620598eebcc140f06b40158fb4edd676e2c756e145dd6942463c58fbaa3392760e26831b49d0c0b82c440652bb5c6b63b452ee6539c9c9cc0fefa55d3895f6d780bfc6d9524a362b0a8e2bed0e606912048d055989a0006b365e8e3cdd2b0abb6f553828e209ee9b4ef2b9d6ec58f9e61b861f4c8d1c886a1949041dc45a1e900c3a58e81b8b260a78a95e04db2f8ef1ecb9b8df75e84f2ad882368c7e8cb628e9a8b8bdc9412c790b42667d4ee0aa0de17db6e06e5a73236a199546c551828e031d753f4b15619882411c08c459bf4b835873f5806e7ce4f7af72b497973329c190fbac351f239c123467fa880fd653b720ce0ed099a9ef54ea14fd791978123e5699986f627e67d412616a2cabef2138e1ef2e753b70cc4d9832380ca466208a82388d133c484aef63820e6c40b1ab3124939c93893cce84d593256b9f037593c3aca3728d10e33c953bd63153f8994f2d0cf57288ce1f690de1f86fe88708a2afc4ec6be4aba19a0e9554f07ea1f263a21c11820f81554f983a19a15208e20d45b348aac383007f3d0cd7a49646fbce4e89fe92afdc173ff003a176119bc149d17b0d22fef18fc8e85aa094feedb45eccce3f0a1fcf42f6655643c18107c8da13d1d7ab2004a38d443660699d4e236687034b21d4a09e64e60369340359b106524bbd335e6d436dd002d75d2ba1a86538104020f10703680e4f21ed446e8fb8414f051c6d9624a3dd7051b8545e53ceedbd1f21035a0e9078a5ea73a594a91a88a1f03eb32095c1d77085fbcd45f3b491e4ebac137dbc17abf8ec5f2a71ef1ba9f7568791622d024483522851e4078e9193a4a3eda2b7cc1b64223275c6cc9e40ddf2b655347c6e38fe153e76f492b77a32be619be569a071de707cd3f3b4519e120fce968631c645fcab678138bb1f921b7a4235eeab37cee5b2f91fbaaa9f3bf6c99a5235c8ec7c94aaf95b228a2235aa283e34af9ff00bf3fffd9');
INSERT INTO public.login("user", pass, tipo, vrt_grp, lgpd) VALUES ('ADMIN', '31994', 'ADMINISTRADOR', 'TODOS', false);
