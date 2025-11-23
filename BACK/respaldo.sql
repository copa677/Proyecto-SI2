--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

-- Started on 2025-11-05 18:46:33

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 278 (class 1255 OID 35650)
-- Name: actualizar_empleado(character varying, character varying, character varying, character varying, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.actualizar_empleado(IN p_nombre_completo character varying, IN p_direccion character varying, IN p_telefono character varying, IN p_rol character varying, IN p_fecha_nacimiento date, IN p_estado character varying, IN p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verificamos si existe un empleado con ese id_usuario
    IF NOT EXISTS (SELECT 1 FROM personal WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'No se encontró un empleado con id_usuario: %', p_id_usuario;
    END IF;

    -- Realizamos la actualización
    UPDATE personal
    SET 
        nombre_completo = p_nombre_completo,
        direccion = p_direccion,
        telefono = p_telefono,
        rol = p_rol,
        fecha_nacimiento = p_fecha_nacimiento,
        estado = p_estado
    WHERE id_usuario = p_id_usuario;

	IF p_estado IS NOT NULL THEN
            UPDATE usuarios
            SET estado = p_estado
            WHERE id = p_id_usuario;
        END IF;
END;
$$;


ALTER PROCEDURE public.actualizar_empleado(IN p_nombre_completo character varying, IN p_direccion character varying, IN p_telefono character varying, IN p_rol character varying, IN p_fecha_nacimiento date, IN p_estado character varying, IN p_id_usuario integer) OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 35651)
-- Name: actualizar_turno_por_dia_y_nombre(character varying, character varying, character varying, time without time zone, time without time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.actualizar_turno_por_dia_y_nombre(IN p_nombre_personal character varying, IN p_dia character varying, IN p_descripcion character varying, IN p_hora_entrada time without time zone, IN p_hora_salida time without time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_personal   INTEGER;
    v_id_turno      INTEGER;
    v_coincidencias INTEGER;
BEGIN
    -- 1) Validar horas
    IF p_hora_entrada >= p_hora_salida THEN
        RAISE EXCEPTION
            'La hora_entrada (%) debe ser menor que la hora_salida (%)',
            p_hora_entrada, p_hora_salida;
    END IF;

    -- 2) Obtener personal
    SELECT id
      INTO v_id_personal
      FROM personal
     WHERE nombre_completo = p_nombre_personal;

    IF v_id_personal IS NULL THEN
        RAISE EXCEPTION 'No existe personal con nombre: %', p_nombre_personal;
    END IF;

    -- 3) Ver cuántos turnos activos hay ese día (para evitar ambigüedad)
    SELECT COUNT(*)
      INTO v_coincidencias
      FROM turnos
     WHERE id_personal = v_id_personal
       AND dia = p_dia
       AND estado = 'active';

    IF v_coincidencias = 0 THEN
        RAISE EXCEPTION 'No existe turno activo para % el día %', p_nombre_personal, p_dia;
    ELSIF v_coincidencias > 1 THEN
        RAISE EXCEPTION 'Hay % turnos activos para % el día %, especifica cuál (hay ambigüedad).',
                        v_coincidencias, p_nombre_personal, p_dia;
    END IF;

    -- 4) Identificar el turno activo único de ese día
    SELECT id
      INTO v_id_turno
      FROM turnos
     WHERE id_personal = v_id_personal
       AND dia = p_dia
       AND estado = 'active'
     LIMIT 1;

    -- 5) Evitar solapamiento con otros turnos activos del mismo día (excluyendo el que se actualiza)
    IF EXISTS (
        SELECT 1
          FROM turnos t
         WHERE t.id_personal = v_id_personal
           AND t.dia = p_dia
           AND t.estado = 'active'
           AND t.id <> v_id_turno
           AND (p_hora_entrada < t.hora_salida AND p_hora_salida > t.hora_entrada)
    ) THEN
        RAISE EXCEPTION
            'El horario propuesto se superpone con otro turno activo para % el día %',
            p_nombre_personal, p_dia;
    END IF;

    -- 6) Actualizar
    UPDATE turnos
       SET descripcion  = p_descripcion,
           hora_entrada = p_hora_entrada,
           hora_salida  = p_hora_salida
     WHERE id = v_id_turno;
END;
$$;


ALTER PROCEDURE public.actualizar_turno_por_dia_y_nombre(IN p_nombre_personal character varying, IN p_dia character varying, IN p_descripcion character varying, IN p_hora_entrada time without time zone, IN p_hora_salida time without time zone) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 35652)
-- Name: agregar_turno_a_personal(character varying, character varying, time without time zone, time without time zone, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.agregar_turno_a_personal(IN p_descripcion character varying, IN p_dia character varying, IN p_hora_entrada time without time zone, IN p_hora_salida time without time zone, IN p_nombre_personal character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_personal INTEGER;
BEGIN
    -- 1) Validar horas
    IF p_hora_entrada >= p_hora_salida THEN
        RAISE EXCEPTION
            'La hora_entrada (%) debe ser menor que la hora_salida (%)',
            p_hora_entrada, p_hora_salida;
    END IF;

    -- 2) Buscar el personal por nombre (tu tabla lo tiene UNIQUE)
    SELECT id
      INTO v_id_personal
      FROM personal
     WHERE nombre_completo = p_nombre_personal;

    IF v_id_personal IS NULL THEN
        RAISE EXCEPTION 'No existe personal con nombre: %', p_nombre_personal;
    END IF;

    -- 3) Evitar solapamientos con turnos activos del mismo día
    --    (solapa si: entrada nueva < salida existente  Y  salida nueva > entrada existente)
    IF EXISTS (
        SELECT 1
          FROM turnos t
         WHERE t.id_personal = v_id_personal
           AND t.dia = p_dia
           AND t.estado = 'active'
           AND (p_hora_entrada < t.hora_salida AND p_hora_salida > t.hora_entrada)
    ) THEN
        RAISE EXCEPTION
            'El turno se superpone con un turno activo existente para % el día %',
            p_nombre_personal, p_dia;
    END IF;

    -- 4) Insertar el turno (estado por defecto: 'active')
    INSERT INTO turnos (descripcion, dia, hora_entrada, hora_salida, estado, id_personal)
    VALUES (p_descripcion, p_dia, p_hora_entrada, p_hora_salida, 'activo', v_id_personal);
END;
$$;


ALTER PROCEDURE public.agregar_turno_a_personal(IN p_descripcion character varying, IN p_dia character varying, IN p_hora_entrada time without time zone, IN p_hora_salida time without time zone, IN p_nombre_personal character varying) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 35653)
-- Name: editar_empleado_usuario(integer, character varying, character varying, character varying, character varying, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.editar_empleado_usuario(IN p_id_usuario integer, IN p_nombre_empleado character varying, IN p_email character varying, IN p_telefono character varying, IN p_direccion character varying, IN p_fecha_nacimiento date)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Actualizar información en la tabla empleado
  UPDATE empleado
  SET 
    nombre_completo = p_nombre_empleado,
    telefono = p_telefono,
    direccion = p_direccion,
    fecha_nacimiento = p_fecha_nacimiento
  WHERE id_usuario = p_id_usuario;

  -- Actualizar email en la tabla usuario
  UPDATE usuario
  SET email = p_email
  WHERE id = p_id_usuario;
END;
$$;


ALTER PROCEDURE public.editar_empleado_usuario(IN p_id_usuario integer, IN p_nombre_empleado character varying, IN p_email character varying, IN p_telefono character varying, IN p_direccion character varying, IN p_fecha_nacimiento date) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 35654)
-- Name: eliminar_empleado_usuario(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.eliminar_empleado_usuario(IN p_id_usuario integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verifica si existe un empleado con ese id_usuario
    IF EXISTS (SELECT 1 FROM empleado WHERE id_usuario = p_id_usuario) THEN
        -- Actualiza el estado del empleado a 'eliminado'
        UPDATE empleado
        SET estado = 'eliminado'
        WHERE id_usuario = p_id_usuario;

        -- También actualiza el estado del usuario a 'eliminado'
        UPDATE usuario
        SET estado = 'eliminado'
        WHERE id = p_id_usuario;
    ELSE
        RAISE EXCEPTION 'No existe un empleado asociado al id_usuario: %', p_id_usuario;
    END IF;
END;
$$;


ALTER PROCEDURE public.eliminar_empleado_usuario(IN p_id_usuario integer) OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 35655)
-- Name: get_permisos_usuario(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_permisos_usuario(p_username character varying) RETURNS TABLE(ventana text, insertar boolean, editar boolean, eliminar boolean, ver boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pe.vista,
        pe.insertar,
        pe.editar,
        pe.eliminar,
        pe.ver
    FROM permisos pe
    JOIN usuarios u ON pe.id_user = u.id
    WHERE u.name_user = p_username;
END;
$$;


ALTER FUNCTION public.get_permisos_usuario(p_username character varying) OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 35656)
-- Name: get_permisos_usuario_ventana(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_permisos_usuario_ventana(p_username character varying, p_ventana character varying) RETURNS TABLE(insertar boolean, editar boolean, eliminar boolean, ver boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        per.insertar,
        per.editar,
        per.eliminar,
        per.ver
    FROM usuarios u
    JOIN permisos per ON per.id_user = u.id
    WHERE u.name_user = p_username AND per.vista = p_ventana;
END;
$$;


ALTER FUNCTION public.get_permisos_usuario_ventana(p_username character varying, p_ventana character varying) OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 35657)
-- Name: insertar_permisos(character varying, character varying, boolean, boolean, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.insertar_permisos(IN p_username character varying, IN p_ventana character varying, IN p_insertar boolean, IN p_editar boolean, IN p_eliminar boolean, IN p_ver boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_usuario INTEGER;
    v_permiso_existente INTEGER;
BEGIN
    -- Obtener el ID del usuario (columna 'id' en tabla usuarios)
    SELECT id INTO v_id_usuario
    FROM usuarios
    WHERE name_user = p_username;

    -- Si no se encuentra el usuario, lanzar error
    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION 'Usuario % no encontrado', p_username;
    END IF;

    -- Verificar si ya existe un permiso para este usuario y ventana
    -- Usar 'id_user' según la estructura real de la tabla permisos
    SELECT id_permiso INTO v_permiso_existente
    FROM permisos
    WHERE id_user = v_id_usuario AND vista = p_ventana;

    -- Si existe, hacer UPDATE
    IF v_permiso_existente IS NOT NULL THEN
        UPDATE permisos
        SET insertar = p_insertar,
            editar = p_editar,
            eliminar = p_eliminar,
            ver = p_ver
        WHERE id_permiso = v_permiso_existente;
        
        RAISE NOTICE 'Permiso actualizado para usuario % en ventana %', p_username, p_ventana;
    ELSE
        -- Si no existe, hacer INSERT
        INSERT INTO permisos(id_user, insertar, editar, eliminar, ver, vista)
        VALUES (v_id_usuario, p_insertar, p_editar, p_eliminar, p_ver, p_ventana);
        
        RAISE NOTICE 'Permiso creado para usuario % en ventana %', p_username, p_ventana;
    END IF;
END;
$$;


ALTER PROCEDURE public.insertar_permisos(IN p_username character varying, IN p_ventana character varying, IN p_insertar boolean, IN p_editar boolean, IN p_eliminar boolean, IN p_ver boolean) OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 35658)
-- Name: obtener_username_por_email(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_username_por_email(p_email text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_username TEXT;
BEGIN
    SELECT username INTO v_username
    FROM usuario
    WHERE email = p_email;

    IF v_username IS NULL THEN
        RAISE EXCEPTION 'No existe un usuario con ese correo electrónico';
    END IF;

    RETURN v_username;
END;
$$;


ALTER FUNCTION public.obtener_username_por_email(p_email text) OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 35659)
-- Name: registrar_empleado(character varying, character varying, character varying, character varying, date, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.registrar_empleado(IN p_nombre_completo character varying, IN p_direccion character varying, IN p_telefono character varying, IN p_rol character varying, IN p_fecha_nacimiento date, IN p_estado character varying, IN p_username character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_usuario INT;
BEGIN
    -- Buscar el ID del usuario a partir del username
    SELECT id INTO v_id_usuario
    FROM usuarios
    WHERE name_user = p_username;

    -- Verificar si se encontró el usuario
    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION 'No se encontró un usuario con el username: %', p_username;
    END IF;

    

    -- Verificar si el usuario ya está vinculado a un empleado
    IF EXISTS (SELECT 1 FROM personal WHERE id_usuario = v_id_usuario) THEN
        RAISE EXCEPTION 'El usuario con username "%" ya está vinculado a un empleado.', p_username;
    END IF;

    -- Insertar el nuevo empleado
    INSERT INTO personal (
        nombre_completo,
        direccion,
        telefono,
        rol,
        fecha_nacimiento,
        id_usuario,
        estado
    ) VALUES (
        p_nombre_completo,
        p_direccion,
        p_telefono,
        p_rol,
        p_fecha_nacimiento,
        v_id_usuario,
        p_estado
    );
END;
$$;


ALTER PROCEDURE public.registrar_empleado(IN p_nombre_completo character varying, IN p_direccion character varying, IN p_telefono character varying, IN p_rol character varying, IN p_fecha_nacimiento date, IN p_estado character varying, IN p_username character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 35660)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 35663)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 35664)
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 35667)
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 221 (class 1259 OID 35668)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 35671)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 35672)
-- Name: auth_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 35677)
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 35680)
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 226 (class 1259 OID 35681)
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 227 (class 1259 OID 35682)
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 35685)
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auth_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 35686)
-- Name: bitacora; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bitacora (
    id_bitacora integer NOT NULL,
    username character varying(100) NOT NULL,
    ip character varying(45) NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    accion text NOT NULL,
    descripcion text NOT NULL
);


ALTER TABLE public.bitacora OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 35691)
-- Name: bitacora_id_bitacora_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bitacora_id_bitacora_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bitacora_id_bitacora_seq OWNER TO postgres;

--
-- TOC entry 5183 (class 0 OID 0)
-- Dependencies: 230
-- Name: bitacora_id_bitacora_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bitacora_id_bitacora_seq OWNED BY public.bitacora.id_bitacora;


--
-- TOC entry 265 (class 1259 OID 36162)
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes (
    id integer NOT NULL,
    nombre_completo character varying(100),
    direccion character varying(255),
    telefono character varying(15),
    fecha_nacimiento date,
    id_usuario integer,
    estado character varying(20)
);


ALTER TABLE public.clientes OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 36161)
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clientes_id_seq OWNER TO postgres;

--
-- TOC entry 5184 (class 0 OID 0)
-- Dependencies: 264
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- TOC entry 231 (class 1259 OID 35692)
-- Name: control_asistencia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.control_asistencia (
    id_control integer NOT NULL,
    fecha date DEFAULT CURRENT_DATE NOT NULL,
    hora_marcado time without time zone DEFAULT CURRENT_TIME NOT NULL,
    estado character varying(20) NOT NULL,
    id_personal integer NOT NULL,
    id_turno integer NOT NULL
);


ALTER TABLE public.control_asistencia OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 35697)
-- Name: control_asistencia_id_control_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.control_asistencia_id_control_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.control_asistencia_id_control_seq OWNER TO postgres;

--
-- TOC entry 5185 (class 0 OID 0)
-- Dependencies: 232
-- Name: control_asistencia_id_control_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.control_asistencia_id_control_seq OWNED BY public.control_asistencia.id_control;


--
-- TOC entry 233 (class 1259 OID 35698)
-- Name: control_calidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.control_calidad (
    id_control integer NOT NULL,
    observaciones text,
    resultado character varying(100) NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    id_personal integer NOT NULL,
    id_trazabilidad integer NOT NULL
);


ALTER TABLE public.control_calidad OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 35703)
-- Name: control_calidad_id_control_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.control_calidad_id_control_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.control_calidad_id_control_seq OWNER TO postgres;

--
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 234
-- Name: control_calidad_id_control_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.control_calidad_id_control_seq OWNED BY public.control_calidad.id_control;


--
-- TOC entry 235 (class 1259 OID 35704)
-- Name: detalle_nota_salida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_nota_salida (
    id_detalle integer NOT NULL,
    id_salida integer NOT NULL,
    id_lote integer NOT NULL,
    nombre_materia_prima character varying(255) NOT NULL,
    cantidad numeric(10,2) NOT NULL,
    unidad_medida character varying(50) NOT NULL
);


ALTER TABLE public.detalle_nota_salida OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 35707)
-- Name: detalle_nota_salida_id_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.detalle_nota_salida_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.detalle_nota_salida_id_detalle_seq OWNER TO postgres;

--
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 236
-- Name: detalle_nota_salida_id_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.detalle_nota_salida_id_detalle_seq OWNED BY public.detalle_nota_salida.id_detalle;


--
-- TOC entry 271 (class 1259 OID 36519)
-- Name: detalle_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_pedido (
    id_detalle integer NOT NULL,
    id_pedido integer NOT NULL,
    tipo_prenda character varying(50) NOT NULL,
    cuello character varying(20) NOT NULL,
    manga character varying(20) NOT NULL,
    color character varying(100) NOT NULL,
    talla character varying(50) NOT NULL,
    material character varying(255) NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) GENERATED ALWAYS AS (((cantidad)::numeric * precio_unitario)) STORED,
    CONSTRAINT detalle_pedido_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT detalle_pedido_tipo_prenda_check CHECK (((tipo_prenda)::text = ANY ((ARRAY['polera'::character varying, 'camisa'::character varying])::text[])))
);


ALTER TABLE public.detalle_pedido OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 36518)
-- Name: detalle_pedido_id_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.detalle_pedido_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.detalle_pedido_id_detalle_seq OWNER TO postgres;

--
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 270
-- Name: detalle_pedido_id_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.detalle_pedido_id_detalle_seq OWNED BY public.detalle_pedido.id_detalle;


--
-- TOC entry 237 (class 1259 OID 35708)
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 35714)
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 35715)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 35718)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 241 (class 1259 OID 35719)
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 35724)
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 243 (class 1259 OID 35725)
-- Name: django_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 36536)
-- Name: facturas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.facturas (
    id_factura integer NOT NULL,
    id_pedido integer NOT NULL,
    cod_factura character varying(100) NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    monto_total numeric(10,2) NOT NULL,
    stripe_payment_intent_id character varying(255),
    stripe_checkout_session_id character varying(255),
    estado_pago character varying(20) DEFAULT 'pendiente'::character varying,
    metodo_pago character varying(50),
    fecha_pago timestamp without time zone,
    codigo_autorizacion character varying(100),
    ultimos_digitos_tarjeta character varying(4),
    tipo_tarjeta character varying(50)
);


ALTER TABLE public.facturas OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 36535)
-- Name: facturas_id_factura_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.facturas_id_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facturas_id_factura_seq OWNER TO postgres;

--
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 272
-- Name: facturas_id_factura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.facturas_id_factura_seq OWNED BY public.facturas.id_factura;


--
-- TOC entry 244 (class 1259 OID 35730)
-- Name: inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario (
    id_inventario integer NOT NULL,
    nombre_materia_prima character varying(255) NOT NULL,
    cantidad_actual numeric(10,2) NOT NULL,
    unidad_medida character varying(50) NOT NULL,
    ubicacion character varying(255),
    estado character varying(50),
    fecha_actualizacion timestamp without time zone,
    id_lote integer NOT NULL,
    stock_minimo numeric(10,2) DEFAULT 0
);


ALTER TABLE public.inventario OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 35735)
-- Name: inventario_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_id_inventario_seq OWNER TO postgres;

--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 245
-- Name: inventario_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_id_inventario_seq OWNED BY public.inventario.id_inventario;


--
-- TOC entry 246 (class 1259 OID 35736)
-- Name: lotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lotes (
    id_lote integer NOT NULL,
    codigo_lote character varying(100) NOT NULL,
    fecha_recepcion date NOT NULL,
    cantidad numeric(10,2) NOT NULL,
    estado character varying(50) NOT NULL,
    id_materia integer NOT NULL
);


ALTER TABLE public.lotes OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 35739)
-- Name: lotes_id_lote_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lotes_id_lote_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lotes_id_lote_seq OWNER TO postgres;

--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 247
-- Name: lotes_id_lote_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lotes_id_lote_seq OWNED BY public.lotes.id_lote;


--
-- TOC entry 248 (class 1259 OID 35740)
-- Name: materias_primas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.materias_primas (
    id_materia integer NOT NULL,
    nombre character varying(255) NOT NULL,
    tipo_material character varying(100)
);


ALTER TABLE public.materias_primas OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 35743)
-- Name: materias_primas_id_materia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.materias_primas_id_materia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.materias_primas_id_materia_seq OWNER TO postgres;

--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 249
-- Name: materias_primas_id_materia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.materias_primas_id_materia_seq OWNED BY public.materias_primas.id_materia;


--
-- TOC entry 275 (class 1259 OID 36554)
-- Name: modelos_prediccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modelos_prediccion (
    id_modelo integer NOT NULL,
    nombre_modelo character varying(255) NOT NULL,
    tipo_modelo character varying(100) NOT NULL,
    "precision" numeric(5,2),
    fecha_entrenamiento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    parametros jsonb,
    activo boolean DEFAULT true
);


ALTER TABLE public.modelos_prediccion OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 36553)
-- Name: modelos_prediccion_id_modelo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modelos_prediccion_id_modelo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modelos_prediccion_id_modelo_seq OWNER TO postgres;

--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 274
-- Name: modelos_prediccion_id_modelo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modelos_prediccion_id_modelo_seq OWNED BY public.modelos_prediccion.id_modelo;


--
-- TOC entry 250 (class 1259 OID 35744)
-- Name: nota_salida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nota_salida (
    id_salida integer NOT NULL,
    fecha_salida date NOT NULL,
    motivo text,
    estado character varying(50) NOT NULL,
    id_personal integer NOT NULL
);


ALTER TABLE public.nota_salida OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 35749)
-- Name: nota_salida_id_salida_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nota_salida_id_salida_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nota_salida_id_salida_seq OWNER TO postgres;

--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 251
-- Name: nota_salida_id_salida_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nota_salida_id_salida_seq OWNED BY public.nota_salida.id_salida;


--
-- TOC entry 252 (class 1259 OID 35750)
-- Name: orden_produccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orden_produccion (
    id_orden integer NOT NULL,
    cod_orden character varying(100) NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    fecha_entrega date,
    estado character varying(50) NOT NULL,
    producto_modelo character varying(255) NOT NULL,
    color character varying(100),
    talla character varying(50),
    cantidad_total integer NOT NULL,
    id_personal integer NOT NULL,
    CONSTRAINT orden_produccion_cantidad_total_check CHECK ((cantidad_total > 0))
);


ALTER TABLE public.orden_produccion OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 35756)
-- Name: orden_produccion_id_orden_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orden_produccion_id_orden_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orden_produccion_id_orden_seq OWNER TO postgres;

--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 253
-- Name: orden_produccion_id_orden_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orden_produccion_id_orden_seq OWNED BY public.orden_produccion.id_orden;


--
-- TOC entry 269 (class 1259 OID 36501)
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    id_pedido integer NOT NULL,
    cod_pedido character varying(100) NOT NULL,
    fecha_pedido timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_prometida date NOT NULL,
    estado character varying(50) NOT NULL,
    id_cliente integer NOT NULL,
    total numeric(10,2) NOT NULL,
    observaciones text,
    fecha_creacion date NOT NULL,
    CONSTRAINT pedidos_estado_check CHECK (((estado)::text = ANY ((ARRAY['cotizacion'::character varying, 'confirmado'::character varying, 'en_produccion'::character varying, 'completado'::character varying, 'entregado'::character varying, 'cancelado'::character varying])::text[])))
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 36500)
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedidos_id_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedidos_id_pedido_seq OWNER TO postgres;

--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 268
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedidos_id_pedido_seq OWNED BY public.pedidos.id_pedido;


--
-- TOC entry 254 (class 1259 OID 35757)
-- Name: permisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    id_user integer NOT NULL,
    insertar boolean DEFAULT false NOT NULL,
    editar boolean DEFAULT false NOT NULL,
    eliminar boolean DEFAULT false NOT NULL,
    ver boolean DEFAULT true NOT NULL,
    vista text NOT NULL
);


ALTER TABLE public.permisos OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 35766)
-- Name: permisos_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permisos_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permisos_id_permiso_seq OWNER TO postgres;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 255
-- Name: permisos_id_permiso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permisos_id_permiso_seq OWNED BY public.permisos.id_permiso;


--
-- TOC entry 256 (class 1259 OID 35767)
-- Name: personal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal (
    id integer NOT NULL,
    nombre_completo character varying(100),
    direccion character varying(255),
    telefono character varying(15),
    rol character varying(100),
    fecha_nacimiento date,
    id_usuario integer,
    estado character varying(20)
);


ALTER TABLE public.personal OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 35770)
-- Name: personal_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_id_seq OWNER TO postgres;

--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 257
-- Name: personal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personal_id_seq OWNED BY public.personal.id;


--
-- TOC entry 267 (class 1259 OID 36196)
-- Name: precios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.precios (
    id_precio integer NOT NULL,
    decripcion character varying(255) NOT NULL,
    material character varying(255),
    talla character varying(50),
    precio_base numeric(10,2) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE public.precios OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 36195)
-- Name: precios_id_precio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.precios_id_precio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.precios_id_precio_seq OWNER TO postgres;

--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 266
-- Name: precios_id_precio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.precios_id_precio_seq OWNED BY public.precios.id_precio;


--
-- TOC entry 277 (class 1259 OID 36565)
-- Name: predicciones_pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.predicciones_pedidos (
    id_prediccion integer NOT NULL,
    id_modelo integer,
    fecha_prediccion date NOT NULL,
    cantidad_predicha integer NOT NULL,
    monto_predicho numeric(10,2) NOT NULL,
    intervalo_confianza numeric(5,2) NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.predicciones_pedidos OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 36564)
-- Name: predicciones_pedidos_id_prediccion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.predicciones_pedidos_id_prediccion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.predicciones_pedidos_id_prediccion_seq OWNER TO postgres;

--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 276
-- Name: predicciones_pedidos_id_prediccion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.predicciones_pedidos_id_prediccion_seq OWNED BY public.predicciones_pedidos.id_prediccion;


--
-- TOC entry 258 (class 1259 OID 35771)
-- Name: trazabilidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trazabilidad (
    id_trazabilidad integer NOT NULL,
    proceso character varying(255) NOT NULL,
    descripcion_proceso text,
    fecha_registro date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone,
    cantidad integer,
    estado character varying(50) NOT NULL,
    id_personal integer NOT NULL,
    id_orden integer NOT NULL
);


ALTER TABLE public.trazabilidad OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 35776)
-- Name: trazabilidad_id_trazabilidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trazabilidad_id_trazabilidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trazabilidad_id_trazabilidad_seq OWNER TO postgres;

--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 259
-- Name: trazabilidad_id_trazabilidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trazabilidad_id_trazabilidad_seq OWNED BY public.trazabilidad.id_trazabilidad;


--
-- TOC entry 260 (class 1259 OID 35777)
-- Name: turnos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.turnos (
    id integer NOT NULL,
    turno character varying(10),
    hora_entrada time without time zone NOT NULL,
    hora_salida time without time zone NOT NULL,
    estado character varying(20) NOT NULL
);


ALTER TABLE public.turnos OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 35780)
-- Name: turnos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.turnos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.turnos_id_seq OWNER TO postgres;

--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 261
-- Name: turnos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.turnos_id_seq OWNED BY public.turnos.id;


--
-- TOC entry 262 (class 1259 OID 35781)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    name_user character varying(50) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    tipo_usuario character varying(50),
    estado character varying(20)
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 35786)
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 263
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- TOC entry 4800 (class 2604 OID 35787)
-- Name: bitacora id_bitacora; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bitacora ALTER COLUMN id_bitacora SET DEFAULT nextval('public.bitacora_id_bitacora_seq'::regclass);


--
-- TOC entry 4821 (class 2604 OID 36165)
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- TOC entry 4801 (class 2604 OID 35788)
-- Name: control_asistencia id_control; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_asistencia ALTER COLUMN id_control SET DEFAULT nextval('public.control_asistencia_id_control_seq'::regclass);


--
-- TOC entry 4804 (class 2604 OID 35789)
-- Name: control_calidad id_control; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_calidad ALTER COLUMN id_control SET DEFAULT nextval('public.control_calidad_id_control_seq'::regclass);


--
-- TOC entry 4805 (class 2604 OID 35790)
-- Name: detalle_nota_salida id_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_nota_salida ALTER COLUMN id_detalle SET DEFAULT nextval('public.detalle_nota_salida_id_detalle_seq'::regclass);


--
-- TOC entry 4826 (class 2604 OID 36522)
-- Name: detalle_pedido id_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido ALTER COLUMN id_detalle SET DEFAULT nextval('public.detalle_pedido_id_detalle_seq'::regclass);


--
-- TOC entry 4828 (class 2604 OID 36539)
-- Name: facturas id_factura; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas ALTER COLUMN id_factura SET DEFAULT nextval('public.facturas_id_factura_seq'::regclass);


--
-- TOC entry 4806 (class 2604 OID 35791)
-- Name: inventario id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_id_inventario_seq'::regclass);


--
-- TOC entry 4808 (class 2604 OID 35792)
-- Name: lotes id_lote; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lotes ALTER COLUMN id_lote SET DEFAULT nextval('public.lotes_id_lote_seq'::regclass);


--
-- TOC entry 4809 (class 2604 OID 35793)
-- Name: materias_primas id_materia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materias_primas ALTER COLUMN id_materia SET DEFAULT nextval('public.materias_primas_id_materia_seq'::regclass);


--
-- TOC entry 4831 (class 2604 OID 36557)
-- Name: modelos_prediccion id_modelo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelos_prediccion ALTER COLUMN id_modelo SET DEFAULT nextval('public.modelos_prediccion_id_modelo_seq'::regclass);


--
-- TOC entry 4810 (class 2604 OID 35794)
-- Name: nota_salida id_salida; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_salida ALTER COLUMN id_salida SET DEFAULT nextval('public.nota_salida_id_salida_seq'::regclass);


--
-- TOC entry 4811 (class 2604 OID 35795)
-- Name: orden_produccion id_orden; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_produccion ALTER COLUMN id_orden SET DEFAULT nextval('public.orden_produccion_id_orden_seq'::regclass);


--
-- TOC entry 4824 (class 2604 OID 36504)
-- Name: pedidos id_pedido; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id_pedido SET DEFAULT nextval('public.pedidos_id_pedido_seq'::regclass);


--
-- TOC entry 4812 (class 2604 OID 35796)
-- Name: permisos id_permiso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id_permiso SET DEFAULT nextval('public.permisos_id_permiso_seq'::regclass);


--
-- TOC entry 4817 (class 2604 OID 35797)
-- Name: personal id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal ALTER COLUMN id SET DEFAULT nextval('public.personal_id_seq'::regclass);


--
-- TOC entry 4822 (class 2604 OID 36199)
-- Name: precios id_precio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precios ALTER COLUMN id_precio SET DEFAULT nextval('public.precios_id_precio_seq'::regclass);


--
-- TOC entry 4834 (class 2604 OID 36568)
-- Name: predicciones_pedidos id_prediccion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predicciones_pedidos ALTER COLUMN id_prediccion SET DEFAULT nextval('public.predicciones_pedidos_id_prediccion_seq'::regclass);


--
-- TOC entry 4818 (class 2604 OID 35798)
-- Name: trazabilidad id_trazabilidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trazabilidad ALTER COLUMN id_trazabilidad SET DEFAULT nextval('public.trazabilidad_id_trazabilidad_seq'::regclass);


--
-- TOC entry 4819 (class 2604 OID 35799)
-- Name: turnos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos ALTER COLUMN id SET DEFAULT nextval('public.turnos_id_seq'::regclass);


--
-- TOC entry 4820 (class 2604 OID 35800)
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- TOC entry 5117 (class 0 OID 35660)
-- Dependencies: 217
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- TOC entry 5119 (class 0 OID 35664)
-- Dependencies: 219
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- TOC entry 5121 (class 0 OID 35668)
-- Dependencies: 221
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	2	add_permission
6	Can change permission	2	change_permission
7	Can delete permission	2	delete_permission
8	Can view permission	2	view_permission
9	Can add group	3	add_group
10	Can change group	3	change_group
11	Can delete group	3	delete_group
12	Can view group	3	view_group
13	Can add user	4	add_user
14	Can change user	4	change_user
15	Can delete user	4	delete_user
16	Can view user	4	view_user
17	Can add content type	5	add_contenttype
18	Can change content type	5	change_contenttype
19	Can delete content type	5	delete_contenttype
20	Can view content type	5	view_contenttype
21	Can add session	6	add_session
22	Can change session	6	change_session
23	Can delete session	6	delete_session
24	Can view session	6	view_session
25	Can add usurios	7	add_usurios
26	Can change usurios	7	change_usurios
27	Can delete usurios	7	delete_usurios
28	Can view usurios	7	view_usurios
29	Can add empleado	8	add_empleado
30	Can change empleado	8	change_empleado
31	Can delete empleado	8	delete_empleado
32	Can view empleado	8	view_empleado
33	Can add personal	9	add_personal
34	Can change personal	9	change_personal
35	Can delete personal	9	delete_personal
36	Can view personal	9	view_personal
37	Can add turnos	10	add_turnos
38	Can change turnos	10	change_turnos
39	Can delete turnos	10	delete_turnos
40	Can view turnos	10	view_turnos
\.


--
-- TOC entry 5123 (class 0 OID 35672)
-- Dependencies: 223
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) FROM stdin;
\.


--
-- TOC entry 5124 (class 0 OID 35677)
-- Dependencies: 224
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- TOC entry 5127 (class 0 OID 35682)
-- Dependencies: 227
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- TOC entry 5129 (class 0 OID 35686)
-- Dependencies: 229
-- Data for Name: bitacora; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bitacora (id_bitacora, username, ip, fecha_hora, accion, descripcion) FROM stdin;
1	copa3	127.0.0.1	2025-10-09 12:13:21.898647	INICIO_SESION	Usuario inició sesión en el sistema
2	copa3	127.0.0.1	2025-10-09 12:15:02.456424	INICIO_SESION	Usuario inició sesión en el sistema
3	copa3	127.0.0.1	2025-10-11 20:27:57.18174	INICIO_SESION	Usuario inició sesión en el sistema
4	copa3	127.0.0.1	2025-10-11 23:21:46.234585	INICIO_SESION	Usuario inició sesión en el sistema
5	copa3	127.0.0.1	2025-10-11 23:21:47.433591	INICIO_SESION	Usuario inició sesión en el sistema
6	copa3	127.0.0.1	2025-10-11 23:33:33.397125	INICIO_SESION	Usuario inició sesión en el sistema
7	copa3	127.0.0.1	2025-10-12 00:55:21.678747	INICIO_SESION	Usuario inició sesión en el sistema
8	copa3	127.0.0.1	2025-10-12 01:46:33.4547	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Usuarios)
9	copa3	127.0.0.1	2025-10-12 02:31:41.836745	INICIO_SESION	Usuario inició sesión en el sistema
10	copa3	127.0.0.1	2025-10-12 22:44:45.114575	INICIO_SESION	Usuario inició sesión en el sistema
11	copa3	127.0.0.1	2025-10-17 03:45:44.048821	INICIO_SESION	Usuario inició sesión en el sistema
12	copa3	181.115.172.152	2025-10-16 23:45:44	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
13	copa3	181.115.172.152	2025-10-16 23:46:12	Cierre de sesión	El usuario copa3 ha cerrado sesión en el sistema
14	copa3	127.0.0.1	2025-10-17 03:46:23.371541	INICIO_SESION	Usuario inició sesión en el sistema
15	copa3	181.115.172.152	2025-10-16 23:46:23	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
16	copa3	181.115.172.152	2025-10-16 23:52:18	Cierre de sesión	El usuario copa3 ha cerrado sesión en el sistema
17	copa3	127.0.0.1	2025-10-17 03:52:27.460378	INICIO_SESION	Usuario inició sesión en el sistema
18	copa3	181.115.172.152	2025-10-16 23:52:27	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
19	copa3	181.115.172.152	2025-10-16 23:52:55	Cierre de sesión	El usuario copa3 ha cerrado sesión en el sistema
20	copa3	127.0.0.1	2025-10-17 03:53:06.658062	INICIO_SESION	Usuario inició sesión en el sistema
21	copa3	181.115.172.152	2025-10-16 23:53:07	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
22	copa3	181.115.172.152	2025-10-17 00:05:13	Cierre de sesión	El usuario copa3 ha cerrado sesión en el sistema
23	copa3	127.0.0.1	2025-10-17 04:05:22.64673	INICIO_SESION	Usuario inició sesión en el sistema
24	copa3	181.115.172.152	2025-10-17 00:05:22	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
25	copa3	181.115.172.152	2025-10-17 00:05:37	Cierre de sesión	El usuario copa3 ha cerrado sesión en el sistema
26	copa3	127.0.0.1	2025-10-17 04:05:46.5325	INICIO_SESION	Usuario inició sesión en el sistema
27	copa3	181.115.172.152	2025-10-17 00:05:46	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
28	copa3	127.0.0.1	2025-10-17 04:14:45.785755	INICIO_SESION	Usuario inició sesión en el sistema
29	copa3	181.115.172.152	2025-10-17 00:14:46	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
30	copa3	127.0.0.1	2025-10-17 04:15:59.374557	INICIO_SESION	Usuario inició sesión en el sistema
31	copa3	181.115.172.152	2025-10-17 00:15:59	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
32	copa3	181.115.172.152	2025-10-17 00:16:56	Cierre de sesión	El usuario copa3 ha cerrado sesión
33	copa3	127.0.0.1	2025-10-17 04:17:16.666445	INICIO_SESION	Usuario inició sesión en el sistema
34	copa3	181.115.172.152	2025-10-17 00:17:16	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
35	copa3	181.115.172.152	2025-10-17 00:20:33	Cierre de sesión	El usuario copa3 ha cerrado sesión
36	copa3	127.0.0.1	2025-10-17 04:24:45.120414	INICIO_SESION	Usuario inició sesión en el sistema
37	copa3	181.115.172.152	2025-10-17 00:24:45	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
38	copa3	127.0.0.1	2025-10-17 04:24:58.596698	INICIO_SESION	Usuario inició sesión en el sistema
39	copa3	181.115.172.152	2025-10-17 00:24:58	Inicio de sesión	El usuario copa3 ha iniciado sesión en el sistema
40	copa3	127.0.0.1	2025-10-17 05:09:11.947551	INICIO_SESION	Usuario inició sesión en el sistema
41	copa3	181.115.172.152	2025-10-17 01:09:24	Cierre de sesión	El usuario copa3 ha cerrado sesión
42	copa3	127.0.0.1	2025-10-17 05:09:33.488042	INICIO_SESION	Usuario inició sesión en el sistema
43	copa3	127.0.0.1	2025-10-17 05:13:56.194737	INICIO_SESION	Usuario inició sesión en el sistema
44	copa3	181.115.172.152	2025-10-17 01:14:46	Cierre de sesión	El usuario copa3 ha cerrado sesión
45	copa3	127.0.0.1	2025-10-17 05:15:02.048602	INICIO_SESION	Usuario inició sesión en el sistema
46	copa3	181.115.172.152	2025-10-17 01:15:56	Cierre de sesión	El usuario copa3 ha cerrado sesión
47	copa3	127.0.0.1	2025-10-17 05:16:25.091599	INICIO_SESION	Usuario inició sesión en el sistema
48	copa3	127.0.0.1	2025-10-19 19:00:12.965276	INICIO_SESION	Usuario inició sesión en el sistema
49	copa3	127.0.0.1	2025-10-19 19:01:06.25666	REGISTRO_ASISTENCIA	Usuario registró una asistencia de empleado (Empleado: D’alessandro Copa Monzon, Estado: Presente)
50	copa3	127.0.0.1	2025-10-19 19:02:56.298512	INICIO_SESION	Usuario inició sesión en el sistema
51	copa3	127.0.0.1	2025-10-19 19:02:57.521396	INICIO_SESION	Usuario inició sesión en el sistema
52	copa3	127.0.0.1	2025-10-19 19:05:45.110316	CREACION	Usuario creó un nuevo registro en Lotes
53	copa3	127.0.0.1	2025-10-19 19:05:58.900548	ACTUALIZACION_COMPLETA	Usuario actualizó información en Lotes
54	copa3	127.0.0.1	2025-10-19 19:08:45.074897	CREACION	Usuario creó un nuevo registro en Lotes
55	copa3	127.0.0.1	2025-10-20 02:45:31.295842	INICIO_SESION	Usuario inició sesión en el sistema
56	copa3	127.0.0.1	2025-10-20 03:18:00.772088	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Personal)
57	copa3	127.0.0.1	2025-10-20 03:18:40.589397	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: manu3, Ventana: Bitacora)
58	copa3	127.0.0.1	2025-10-20 03:23:42.230071	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Personal)
59	copa3	127.0.0.1	2025-10-20 05:41:35.915026	INICIO_SESION	Usuario inició sesión en el sistema
60	copa3	127.0.0.1	2025-10-20 17:31:52.48814	INICIO_SESION	Usuario inició sesión en el sistema
61	copa3	127.0.0.1	2025-10-20 17:44:54.343412	CREACION	Usuario creó un nuevo registro en Inventario
62	copa3	127.0.0.1	2025-10-20 18:14:23.480412	CREACION	Usuario creó un nuevo registro en Ordenproduccion
63	copa3	127.0.0.1	2025-10-20 18:44:25.736282	ACTUALIZACION_USUARIO	Usuario actualizó información de un usuario
64	copa3	127.0.0.1	2025-10-20 18:44:43.343105	ACTUALIZACION_USUARIO	Usuario actualizó información de un usuario
65	copa3	127.0.0.1	2025-10-20 18:45:17.67904	REGISTRO_USUARIO	Se registró un nuevo usuario en el sistema (Email: isaacorellana@gmail.com, Tipo: empleado)
66	copa3	127.0.0.1	2025-10-20 18:47:09.224824	REGISTRO_EMPLEADO	Usuario registró un nuevo empleado en el sistema (Empleado: Isaac Orellana Escobar)
67	copa3	127.0.0.1	2025-10-20 19:00:21.231187	ACTUALIZACION_USUARIO	Usuario actualizó información de un usuario
68	copa3	127.0.0.1	2025-10-20 19:15:44.975974	CREACION	Usuario creó un nuevo registro en Lotes
69	copa3	127.0.0.1	2025-10-20 19:17:21.196045	CREACION	Usuario creó un nuevo registro en Lotes
70	copa3	127.0.0.1	2025-10-20 19:45:25.845833	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: tarde)
71	copa3	127.0.0.1	2025-10-20 19:46:13.66949	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: mañana)
72	copa3	127.0.0.1	2025-10-20 19:46:28.176216	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: mañana)
73	copa3	127.0.0.1	2025-10-20 19:47:24.613237	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: mañana)
74	copa3	127.0.0.1	2025-10-20 19:54:12.692992	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: mañana)
75	copa3	127.0.0.1	2025-10-20 20:04:45.79639	ACTUALIZACION_TURNO	Usuario modificó un turno existente (Turno: mañana)
76	Anónimo	127.0.0.1	2025-10-20 20:04:54.895713	ELIMINACION_TURNO	Usuario eliminó un turno
77	Anónimo	127.0.0.1	2025-10-20 20:05:06.812597	ELIMINACION_TURNO	Usuario eliminó un turno
78	Anónimo	127.0.0.1	2025-10-20 20:05:12.905799	ELIMINACION_TURNO	Usuario eliminó un turno
79	Anónimo	127.0.0.1	2025-10-20 20:05:22.788626	ELIMINACION_TURNO	Usuario eliminó un turno
80	Anónimo	127.0.0.1	2025-10-20 20:05:42.558357	ELIMINACION_TURNO	Usuario eliminó un turno
81	copa3	127.0.0.1	2025-10-20 20:07:40.294782	ACTUALIZACION_TURNO	Usuario modificó un turno existente (Turno: mañana)
82	copa3	127.0.0.1	2025-10-20 20:08:04.169353	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: tarde)
83	Anónimo	127.0.0.1	2025-10-20 20:23:59.685203	ELIMINACION	Usuario eliminó un registro de Lotes
84	Anónimo	127.0.0.1	2025-10-20 20:24:03.360942	ELIMINACION	Usuario eliminó un registro de Lotes
85	Anónimo	127.0.0.1	2025-10-20 20:24:35.141263	ELIMINACION	Usuario eliminó un registro de Ordenproduccion
86	copa3	127.0.0.1	2025-10-20 20:32:11.505858	CREACION	Usuario creó un nuevo registro en Lotes
87	copa3	127.0.0.1	2025-10-20 20:32:28.211051	CREACION	Usuario creó un nuevo registro en Lotes
88	copa3	127.0.0.1	2025-10-20 20:32:50.069969	CREACION	Usuario creó un nuevo registro en Lotes
89	copa3	127.0.0.1	2025-10-20 20:33:17.24921	CREACION	Usuario creó un nuevo registro en Lotes
90	copa3	127.0.0.1	2025-10-20 20:33:37.225299	CREACION	Usuario creó un nuevo registro en Lotes
91	copa3	127.0.0.1	2025-10-20 20:33:49.421026	CREACION	Usuario creó un nuevo registro en Lotes
92	copa3	127.0.0.1	2025-10-20 20:34:01.817077	CREACION	Usuario creó un nuevo registro en Lotes
93	copa3	127.0.0.1	2025-10-20 20:34:14.647458	CREACION	Usuario creó un nuevo registro en Lotes
94	copa3	127.0.0.1	2025-10-20 20:34:27.587756	CREACION	Usuario creó un nuevo registro en Lotes
95	copa3	127.0.0.1	2025-10-20 20:34:40.533042	CREACION	Usuario creó un nuevo registro en Lotes
96	copa3	127.0.0.1	2025-10-20 20:34:55.181103	CREACION	Usuario creó un nuevo registro en Lotes
97	copa3	127.0.0.1	2025-10-20 20:35:04.616682	CREACION	Usuario creó un nuevo registro en Lotes
98	copa3	127.0.0.1	2025-10-20 20:35:23.201749	CREACION	Usuario creó un nuevo registro en Lotes
99	copa3	127.0.0.1	2025-10-20 20:35:39.251393	CREACION	Usuario creó un nuevo registro en Lotes
100	copa3	127.0.0.1	2025-10-20 20:35:52.983351	CREACION	Usuario creó un nuevo registro en Lotes
101	copa3	127.0.0.1	2025-10-20 20:36:23.725871	CREACION	Usuario creó un nuevo registro en Lotes
102	copa3	127.0.0.1	2025-10-20 20:36:44.42179	CREACION	Usuario creó un nuevo registro en Lotes
103	copa3	127.0.0.1	2025-10-20 20:37:04.046578	CREACION	Usuario creó un nuevo registro en Lotes
104	copa3	127.0.0.1	2025-10-20 20:37:18.727437	CREACION	Usuario creó un nuevo registro en Lotes
105	copa3	127.0.0.1	2025-10-20 20:37:33.632465	CREACION	Usuario creó un nuevo registro en Lotes
106	copa3	127.0.0.1	2025-10-20 20:37:46.272864	CREACION	Usuario creó un nuevo registro en Lotes
107	copa3	127.0.0.1	2025-10-20 20:38:30.592825	CREACION	Usuario creó un nuevo registro en Lotes
108	copa3	127.0.0.1	2025-10-20 20:38:45.070352	CREACION	Usuario creó un nuevo registro en Lotes
109	copa3	127.0.0.1	2025-10-20 20:39:00.995616	CREACION	Usuario creó un nuevo registro en Lotes
110	copa3	127.0.0.1	2025-10-20 20:39:15.553273	CREACION	Usuario creó un nuevo registro en Lotes
111	copa3	127.0.0.1	2025-10-20 20:39:25.730931	CREACION	Usuario creó un nuevo registro en Lotes
112	copa3	127.0.0.1	2025-10-20 20:39:38.688674	CREACION	Usuario creó un nuevo registro en Lotes
113	copa3	127.0.0.1	2025-10-20 20:40:13.136367	CREACION	Usuario creó un nuevo registro en Lotes
114	copa3	127.0.0.1	2025-10-20 20:40:33.941082	CREACION	Usuario creó un nuevo registro en Lotes
115	copa3	127.0.0.1	2025-10-20 20:40:48.371652	CREACION	Usuario creó un nuevo registro en Lotes
116	copa3	127.0.0.1	2025-10-20 20:41:01.249555	CREACION	Usuario creó un nuevo registro en Lotes
117	copa3	127.0.0.1	2025-10-20 20:41:13.971804	CREACION	Usuario creó un nuevo registro en Lotes
118	copa3	127.0.0.1	2025-10-20 20:41:27.046918	CREACION	Usuario creó un nuevo registro en Lotes
119	copa3	127.0.0.1	2025-10-20 20:41:39.337585	CREACION	Usuario creó un nuevo registro en Lotes
120	copa3	127.0.0.1	2025-10-20 20:41:55.028817	CREACION	Usuario creó un nuevo registro en Lotes
121	copa3	127.0.0.1	2025-10-20 20:42:09.792905	CREACION	Usuario creó un nuevo registro en Lotes
122	copa3	127.0.0.1	2025-10-20 20:43:26.202285	CREACION	Usuario creó un nuevo registro en Lotes
123	copa3	127.0.0.1	2025-10-20 20:43:44.85084	CREACION	Usuario creó un nuevo registro en Lotes
124	copa3	127.0.0.1	2025-10-20 20:44:03.2524	CREACION	Usuario creó un nuevo registro en Lotes
125	copa3	127.0.0.1	2025-10-20 20:44:18.407164	CREACION	Usuario creó un nuevo registro en Lotes
126	copa3	127.0.0.1	2025-10-20 20:44:33.045341	CREACION	Usuario creó un nuevo registro en Lotes
127	copa3	127.0.0.1	2025-10-20 20:44:50.262492	CREACION	Usuario creó un nuevo registro en Lotes
128	copa3	127.0.0.1	2025-10-20 20:45:11.981644	CREACION	Usuario creó un nuevo registro en Lotes
129	copa3	127.0.0.1	2025-10-20 20:45:43.566739	CREACION	Usuario creó un nuevo registro en Lotes
130	copa3	127.0.0.1	2025-10-20 21:14:23.601586	CREACION	Usuario creó un nuevo registro en Lotes
131	copa3	127.0.0.1	2025-10-20 21:14:44.67106	CREACION	Usuario creó un nuevo registro en Lotes
132	copa3	127.0.0.1	2025-10-20 21:14:59.449243	CREACION	Usuario creó un nuevo registro en Lotes
133	copa3	127.0.0.1	2025-10-20 21:15:48.919614	CREACION	Usuario creó un nuevo registro en Lotes
134	copa3	127.0.0.1	2025-10-20 21:18:37.571332	CREACION	Usuario creó un nuevo registro en Lotes
135	copa3	127.0.0.1	2025-10-20 21:18:50.740299	CREACION	Usuario creó un nuevo registro en Lotes
136	copa3	127.0.0.1	2025-10-20 21:33:01.912743	CREACION	Usuario creó un nuevo registro en Lotes
137	copa3	127.0.0.1	2025-10-20 22:02:42.223403	CREACION	Usuario creó un nuevo registro en Lotes
138	copa3	127.0.0.1	2025-10-20 22:03:51.997638	CREACION	Usuario creó un nuevo registro en Lotes
139	copa3	127.0.0.1	2025-10-20 22:04:59.243228	CREACION	Usuario creó un nuevo registro en Lotes
140	copa3	127.0.0.1	2025-10-20 22:06:00.496137	CREACION	Usuario creó un nuevo registro en Lotes
141	copa3	127.0.0.1	2025-10-20 22:08:22.269154	CREACION	Usuario creó un nuevo registro en Lotes
142	copa3	127.0.0.1	2025-10-20 22:17:59.792442	CREACION	Usuario creó un nuevo registro en Lotes
143	copa3	127.0.0.1	2025-10-20 22:19:34.969485	CREACION	Usuario creó un nuevo registro en Lotes
144	copa3	127.0.0.1	2025-10-20 22:20:53.282198	CREACION	Usuario creó un nuevo registro en Lotes
145	copa3	127.0.0.1	2025-10-20 22:22:11.089096	CREACION	Usuario creó un nuevo registro en Lotes
146	copa3	127.0.0.1	2025-10-20 22:25:52.242337	ACTUALIZACION_COMPLETA	Usuario actualizó información en Inventario
147	copa3	127.0.0.1	2025-10-20 22:29:50.464952	CREACION	Usuario creó un nuevo registro en Ordenproduccion
148	copa3	127.0.0.1	2025-10-20 22:33:54.469473	CREACION	Usuario creó un nuevo registro en Lotes
149	copa3	127.0.0.1	2025-10-20 22:35:37.387479	CREACION	Usuario creó un nuevo registro en Lotes
150	copa3	127.0.0.1	2025-10-20 22:39:37.378398	CREACION	Usuario creó un nuevo registro en Lotes
151	copa3	127.0.0.1	2025-10-20 22:50:08.193129	CREACION	Usuario creó un nuevo registro en Lotes
152	copa3	127.0.0.1	2025-10-20 22:52:25.435762	CREACION	Usuario creó un nuevo registro en Ordenproduccion
153	copa3	127.0.0.1	2025-10-21 02:10:54.467386	INICIO_SESION	Usuario inició sesión en el sistema
154	copa3	127.0.0.1	2025-10-21 02:17:40.013478	CREACION	Usuario creó un nuevo registro en Ordenproduccion
155	copa3	127.0.0.1	2025-10-21 03:29:34.895386	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Usuarios)
156	copa3	127.0.0.1	2025-10-21 03:30:39.519598	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Inventario)
157	copa3	127.0.0.1	2025-10-21 03:30:55.812673	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Bitacora)
158	copa3	127.0.0.1	2025-10-21 03:31:10.497572	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Lotes)
159	copa3	127.0.0.1	2025-10-21 03:33:10.541428	INICIO_SESION	Usuario inició sesión en el sistema
160	copa3	127.0.0.1	2025-10-21 03:35:07.303957	ACTUALIZACION_USUARIO	Usuario actualizó información de un usuario (Tipo: admin)
161	copa3	127.0.0.1	2025-10-21 03:35:16.128627	CIERRE_SESION	Usuario cerró sesión
162	copa3	127.0.0.1	2025-10-21 03:35:30.155521	INICIO_SESION	Usuario inició sesión en el sistema
163	copa3	127.0.0.1	2025-10-21 03:36:40.70763	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: OrdenProduccion)
164	copa3	127.0.0.1	2025-10-21 03:36:59.516704	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: NotaSalida)
165	copa3	127.0.0.1	2025-10-21 03:37:01.066879	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: NotaSalida)
166	copa3	127.0.0.1	2025-10-21 03:37:12.737948	CIERRE_SESION	Usuario cerró sesión
167	copa3	127.0.0.1	2025-10-21 03:37:25.548256	INICIO_SESION	Usuario inició sesión en el sistema
168	copa3	127.0.0.1	2025-10-21 03:43:19.162673	CIERRE_SESION	Usuario cerró sesión
169	copa3	127.0.0.1	2025-10-21 03:43:27.976287	INICIO_SESION	Usuario inició sesión en el sistema
170	copa3	127.0.0.1	2025-10-21 04:07:44.436883	INICIO_SESION	Usuario inició sesión en el sistema
171	copa3	127.0.0.1	2025-10-21 04:17:12.251235	ACTUALIZACION_USUARIO	Usuario actualizó información de un usuario (Tipo: admin)
172	copa3	127.0.0.1	2025-10-21 04:21:11.655963	ACTUALIZACION_TURNO	Usuario modificó un turno existente (Turno: tarde)
173	Anónimo	127.0.0.1	2025-10-21 04:22:31.156776	ELIMINACION_TURNO	Usuario eliminó un turno
174	copa3	127.0.0.1	2025-10-21 04:22:43.892818	CREACION_TURNO	Usuario creó un nuevo turno de trabajo (Turno: tarde)
175	copa3	127.0.0.1	2025-10-21 04:41:22.148513	REGISTRO_USUARIO	Se registró un nuevo usuario en el sistema (Email: mario544@gmail.com, Tipo: admin)
176	mario3	127.0.0.1	2025-10-21 04:41:40.664698	INICIO_SESION	Usuario inició sesión en el sistema
177	mario3	127.0.0.1	2025-10-21 05:15:48.528976	INICIO_SESION	Usuario inició sesión en el sistema
178	copa3	127.0.0.1	2025-10-21 05:16:21.313973	CIERRE_SESION	Usuario cerró sesión
179	mario3	127.0.0.1	2025-10-21 05:17:15.011752	INICIO_SESION	Usuario inició sesión en el sistema
180	mario3	127.0.0.1	2025-10-21 05:17:17.895597	INICIO_SESION	Usuario inició sesión en el sistema
181	mario3	127.0.0.1	2025-10-21 05:17:47.973618	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: mario3, Ventana: OrdenProduccion)
182	mario3	127.0.0.1	2025-10-21 05:18:15.748277	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: mario3, Ventana: NotaSalida)
183	mario3	127.0.0.1	2025-10-21 05:18:22.96388	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: mario3, Ventana: Bitacora)
184	mario3	127.0.0.1	2025-10-21 05:18:29.312754	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: mario3, Ventana: Usuarios)
185	mario3	127.0.0.1	2025-10-21 05:18:32.380169	CIERRE_SESION	Usuario cerró sesión
186	mario3	127.0.0.1	2025-10-21 05:18:52.769065	INICIO_SESION	Usuario inició sesión en el sistema
187	mario3	127.0.0.1	2025-10-21 05:20:28.287238	CIERRE_SESION	Usuario cerró sesión
188	copa3	127.0.0.1	2025-10-21 05:20:39.844054	INICIO_SESION	Usuario inició sesión en el sistema
189	copa3	127.0.0.1	2025-10-21 05:22:35.447699	REGISTRO_EMPLEADO	Usuario registró un nuevo empleado en el sistema (Empleado: Mario Robles)
190	copa3	127.0.0.1	2025-10-21 05:22:42.842896	CIERRE_SESION	Usuario cerró sesión
191	mario3	127.0.0.1	2025-10-21 05:22:55.225632	INICIO_SESION	Usuario inició sesión en el sistema
192	mario3	127.0.0.1	2025-10-21 05:28:21.850275	INICIO_SESION	Usuario inició sesión en el sistema
193	copa3	127.0.0.1	2025-10-21 05:30:02.344444	CIERRE_SESION	Usuario cerró sesión
194	mario3	127.0.0.1	2025-10-21 05:30:29.636072	INICIO_SESION	Usuario inició sesión en el sistema
195	mario3	127.0.0.1	2025-10-21 05:30:38.672709	CIERRE_SESION	Usuario cerró sesión
196	copa3	127.0.0.1	2025-10-21 05:40:43.942101	INICIO_SESION	Usuario inició sesión en el sistema
197	copa3	127.0.0.1	2025-10-21 05:41:04.572614	REGISTRO_EMPLEADO	Usuario registró un nuevo empleado en el sistema (Empleado: D’alessandro Copa Monzon)
198	copa3	172.18.0.1	2025-10-21 06:43:28.86374	INICIO_SESION	Usuario inició sesión en el sistema
199	copa3	172.18.0.1	2025-10-21 06:47:10.728883	INICIO_SESION	Usuario inició sesión en el sistema
200	Anónimo	127.0.0.1	2025-10-21 08:05:40.987388	CREACION	Usuario creó un nuevo registro en Br
201	copa3	127.0.0.1	2025-11-02 14:25:56.688943	INICIO_SESION	Usuario inició sesión en el sistema
202	juan3	127.0.0.1	2025-11-02 16:16:38.501459	CREACION	Usuario creó un nuevo registro en Clientes
203	copa3	127.0.0.1	2025-11-02 16:59:53.067744	INICIO_SESION	Usuario inició sesión en el sistema
204	copa3	127.0.0.1	2025-11-02 17:05:12.238809	ASIGNACION_PERMISOS	Usuario asignó permisos a otro usuario (Para usuario: copa3, Ventana: Clientes)
205	copa3	127.0.0.1	2025-11-02 20:51:00.829784	INICIO_SESION	Usuario inició sesión en el sistema
206	copa3	127.0.0.1	2025-11-02 22:06:29.132903	INICIO_SESION	Usuario inició sesión en el sistema
207	copa3	127.0.0.1	2025-11-03 21:11:54.609217	INICIO_SESION	Usuario inició sesión en el sistema
208	copa3	127.0.0.1	2025-11-03 21:21:08.673104	INICIO_SESION	Usuario inició sesión en el sistema
209	copa3	127.0.0.1	2025-11-03 21:21:10.3685	INICIO_SESION	Usuario inició sesión en el sistema
210	copa3	127.0.0.1	2025-11-03 21:29:21.524431	INICIO_SESION	Usuario inició sesión en el sistema
211	copa3	127.0.0.1	2025-11-03 21:29:24.532599	INICIO_SESION	Usuario inició sesión en el sistema
212	copa3	127.0.0.1	2025-11-05 05:20:24.430561	INICIO_SESION	Usuario inició sesión en el sistema
213	copa3	127.0.0.1	2025-11-05 05:25:29.740525	INICIO_SESION	Usuario inició sesión en el sistema
214	copa3	127.0.0.1	2025-11-05 05:42:44.384693	CREACION	Usuario creó un nuevo registro en Pedidos
215	copa3	127.0.0.1	2025-11-05 05:42:44.583794	CREACION	Usuario creó un nuevo registro en Pedidos
216	copa3	127.0.0.1	2025-11-05 05:42:44.586933	CREACION	Usuario creó un nuevo registro en Pedidos
217	Anónimo	127.0.0.1	2025-11-05 07:37:18.071481	CREACION	Usuario creó un nuevo registro en Pedidos
218	Anónimo	127.0.0.1	2025-11-05 07:40:12.719219	CREACION	Usuario creó un nuevo registro en Pedidos
219	Anónimo	127.0.0.1	2025-11-05 07:47:05.497679	CREACION	Usuario creó un nuevo registro en Facturas
220	carlos_mendoza	127.0.0.1	2025-11-05 12:49:58.014804	CREACION	Usuario creó un nuevo registro en Clientes
221	ana_garcia	127.0.0.1	2025-11-05 12:50:20.819491	CREACION	Usuario creó un nuevo registro en Clientes
222	roberto_silva	127.0.0.1	2025-11-05 12:50:38.811643	CREACION	Usuario creó un nuevo registro en Clientes
223	maria_fernandez	127.0.0.1	2025-11-05 12:50:47.522445	CREACION	Usuario creó un nuevo registro en Clientes
224	jorge_martinez	127.0.0.1	2025-11-05 12:51:02.312631	CREACION	Usuario creó un nuevo registro en Clientes
225	claudia_ramos	127.0.0.1	2025-11-05 12:51:10.474102	CREACION	Usuario creó un nuevo registro en Clientes
226	pablo_gomez	127.0.0.1	2025-11-05 12:51:31.491334	CREACION	Usuario creó un nuevo registro en Clientes
227	lucia_torres	127.0.0.1	2025-11-05 12:51:56.090569	CREACION	Usuario creó un nuevo registro en Clientes
228	miguel_ruiz	127.0.0.1	2025-11-05 12:52:08.395912	CREACION	Usuario creó un nuevo registro en Clientes
229	andrea_castro	127.0.0.1	2025-11-05 12:52:22.534481	CREACION	Usuario creó un nuevo registro en Clientes
230	diego_alvarez	127.0.0.1	2025-11-05 12:52:32.007786	CREACION	Usuario creó un nuevo registro en Clientes
231	patricia_flores	127.0.0.1	2025-11-05 12:52:45.64305	CREACION	Usuario creó un nuevo registro en Clientes
232	oscar_diaz	127.0.0.1	2025-11-05 12:52:57.114279	CREACION	Usuario creó un nuevo registro en Clientes
233	silvia_huaman	127.0.0.1	2025-11-05 12:53:10.426092	CREACION	Usuario creó un nuevo registro en Clientes
234	ricardo_medina	127.0.0.1	2025-11-05 12:53:25.942518	CREACION	Usuario creó un nuevo registro en Clientes
235	Anónimo	127.0.0.1	2025-11-05 14:05:10.614292	CREACION	Usuario creó un nuevo registro en Pedidos
236	Anónimo	127.0.0.1	2025-11-05 14:05:45.352829	CREACION	Usuario creó un nuevo registro en Pedidos
237	Anónimo	127.0.0.1	2025-11-05 14:06:03.408425	CREACION	Usuario creó un nuevo registro en Pedidos
238	Anónimo	127.0.0.1	2025-11-05 14:06:31.407729	CREACION	Usuario creó un nuevo registro en Pedidos
239	Anónimo	127.0.0.1	2025-11-05 14:06:52.030951	CREACION	Usuario creó un nuevo registro en Pedidos
240	Anónimo	127.0.0.1	2025-11-05 14:07:12.327352	CREACION	Usuario creó un nuevo registro en Pedidos
241	Anónimo	127.0.0.1	2025-11-05 14:07:33.093434	CREACION	Usuario creó un nuevo registro en Pedidos
242	Anónimo	127.0.0.1	2025-11-05 14:08:01.413441	CREACION	Usuario creó un nuevo registro en Pedidos
243	Anónimo	127.0.0.1	2025-11-05 14:09:25.216765	CREACION	Usuario creó un nuevo registro en Pedidos
244	Anónimo	127.0.0.1	2025-11-05 14:09:48.04625	CREACION	Usuario creó un nuevo registro en Pedidos
245	Anónimo	127.0.0.1	2025-11-05 14:10:09.086601	CREACION	Usuario creó un nuevo registro en Pedidos
246	Anónimo	127.0.0.1	2025-11-05 14:10:32.828145	CREACION	Usuario creó un nuevo registro en Pedidos
247	Anónimo	127.0.0.1	2025-11-05 14:10:56.161423	CREACION	Usuario creó un nuevo registro en Pedidos
248	Anónimo	127.0.0.1	2025-11-05 14:11:10.563757	CREACION	Usuario creó un nuevo registro en Pedidos
249	Anónimo	127.0.0.1	2025-11-05 14:11:25.846522	CREACION	Usuario creó un nuevo registro en Pedidos
250	Anónimo	127.0.0.1	2025-11-05 14:11:40.191856	CREACION	Usuario creó un nuevo registro en Pedidos
251	Anónimo	127.0.0.1	2025-11-05 14:11:56.859383	CREACION	Usuario creó un nuevo registro en Pedidos
252	Anónimo	127.0.0.1	2025-11-05 14:12:12.412207	CREACION	Usuario creó un nuevo registro en Pedidos
253	Anónimo	127.0.0.1	2025-11-05 14:12:32.302729	CREACION	Usuario creó un nuevo registro en Pedidos
254	Anónimo	127.0.0.1	2025-11-05 14:12:47.540445	CREACION	Usuario creó un nuevo registro en Pedidos
255	Anónimo	127.0.0.1	2025-11-05 14:13:08.225385	CREACION	Usuario creó un nuevo registro en Pedidos
256	Anónimo	127.0.0.1	2025-11-05 14:13:27.973507	CREACION	Usuario creó un nuevo registro en Pedidos
257	Anónimo	127.0.0.1	2025-11-05 14:14:25.061841	CREACION	Usuario creó un nuevo registro en Pedidos
258	Anónimo	127.0.0.1	2025-11-05 14:14:43.823145	CREACION	Usuario creó un nuevo registro en Pedidos
259	Anónimo	127.0.0.1	2025-11-05 14:15:01.375266	CREACION	Usuario creó un nuevo registro en Pedidos
260	Anónimo	127.0.0.1	2025-11-05 14:15:16.839647	CREACION	Usuario creó un nuevo registro en Pedidos
261	Anónimo	127.0.0.1	2025-11-05 14:15:46.010579	CREACION	Usuario creó un nuevo registro en Pedidos
262	Anónimo	127.0.0.1	2025-11-05 14:16:03.500348	CREACION	Usuario creó un nuevo registro en Pedidos
263	Anónimo	127.0.0.1	2025-11-05 14:17:48.760771	CREACION	Usuario creó un nuevo registro en Pedidos
264	Anónimo	127.0.0.1	2025-11-05 14:18:03.46879	CREACION	Usuario creó un nuevo registro en Pedidos
265	Anónimo	127.0.0.1	2025-11-05 14:19:17.983949	CREACION	Usuario creó un nuevo registro en Pedidos
266	Anónimo	127.0.0.1	2025-11-05 14:19:34.413725	CREACION	Usuario creó un nuevo registro en Pedidos
267	Anónimo	127.0.0.1	2025-11-05 14:20:10.519923	CREACION	Usuario creó un nuevo registro en Pedidos
268	Anónimo	127.0.0.1	2025-11-05 14:20:21.177287	CREACION	Usuario creó un nuevo registro en Pedidos
269	Anónimo	127.0.0.1	2025-11-05 14:20:38.7559	CREACION	Usuario creó un nuevo registro en Pedidos
270	Anónimo	127.0.0.1	2025-11-05 14:20:47.27058	CREACION	Usuario creó un nuevo registro en Pedidos
271	Anónimo	127.0.0.1	2025-11-05 14:21:25.331831	CREACION	Usuario creó un nuevo registro en Pedidos
272	Anónimo	127.0.0.1	2025-11-05 14:21:36.188667	CREACION	Usuario creó un nuevo registro en Pedidos
273	Anónimo	127.0.0.1	2025-11-05 14:21:57.576329	CREACION	Usuario creó un nuevo registro en Pedidos
274	Anónimo	127.0.0.1	2025-11-05 14:22:06.105847	CREACION	Usuario creó un nuevo registro en Pedidos
275	Anónimo	127.0.0.1	2025-11-05 14:22:23.238469	CREACION	Usuario creó un nuevo registro en Pedidos
276	Anónimo	127.0.0.1	2025-11-05 14:22:34.694742	CREACION	Usuario creó un nuevo registro en Pedidos
277	Anónimo	127.0.0.1	2025-11-05 14:22:56.102041	CREACION	Usuario creó un nuevo registro en Pedidos
278	Anónimo	127.0.0.1	2025-11-05 14:23:04.43817	CREACION	Usuario creó un nuevo registro en Pedidos
279	Anónimo	127.0.0.1	2025-11-05 14:23:25.591773	CREACION	Usuario creó un nuevo registro en Pedidos
280	Anónimo	127.0.0.1	2025-11-05 14:23:36.92424	CREACION	Usuario creó un nuevo registro en Pedidos
281	Anónimo	127.0.0.1	2025-11-05 14:23:54.114142	CREACION	Usuario creó un nuevo registro en Pedidos
282	Anónimo	127.0.0.1	2025-11-05 14:24:04.684054	CREACION	Usuario creó un nuevo registro en Pedidos
283	Anónimo	127.0.0.1	2025-11-05 14:24:24.592718	CREACION	Usuario creó un nuevo registro en Pedidos
284	Anónimo	127.0.0.1	2025-11-05 14:24:35.930884	CREACION	Usuario creó un nuevo registro en Pedidos
285	Anónimo	127.0.0.1	2025-11-05 14:40:52.591844	CREACION	Usuario creó un nuevo registro en Pedidos
286	Anónimo	127.0.0.1	2025-11-05 14:41:06.280009	CREACION	Usuario creó un nuevo registro en Pedidos
287	Anónimo	127.0.0.1	2025-11-05 14:41:22.325827	CREACION	Usuario creó un nuevo registro en Pedidos
288	Anónimo	127.0.0.1	2025-11-05 14:41:29.322164	CREACION	Usuario creó un nuevo registro en Pedidos
289	Anónimo	127.0.0.1	2025-11-05 14:41:48.900723	CREACION	Usuario creó un nuevo registro en Pedidos
290	Anónimo	127.0.0.1	2025-11-05 14:41:59.050911	CREACION	Usuario creó un nuevo registro en Pedidos
291	Anónimo	127.0.0.1	2025-11-05 14:42:49.960124	CREACION	Usuario creó un nuevo registro en Pedidos
292	Anónimo	127.0.0.1	2025-11-05 14:43:01.839825	CREACION	Usuario creó un nuevo registro en Pedidos
293	Anónimo	127.0.0.1	2025-11-05 14:43:08.850209	CREACION	Usuario creó un nuevo registro en Pedidos
294	Anónimo	127.0.0.1	2025-11-05 14:43:29.467811	CREACION	Usuario creó un nuevo registro en Pedidos
295	Anónimo	127.0.0.1	2025-11-05 14:43:35.953236	CREACION	Usuario creó un nuevo registro en Pedidos
296	Anónimo	127.0.0.1	2025-11-05 14:44:02.996829	CREACION	Usuario creó un nuevo registro en Pedidos
297	Anónimo	127.0.0.1	2025-11-05 14:44:10.658821	CREACION	Usuario creó un nuevo registro en Pedidos
298	Anónimo	127.0.0.1	2025-11-05 14:44:29.727967	CREACION	Usuario creó un nuevo registro en Pedidos
299	Anónimo	127.0.0.1	2025-11-05 14:44:37.72509	CREACION	Usuario creó un nuevo registro en Pedidos
300	Anónimo	127.0.0.1	2025-11-05 14:44:58.192924	CREACION	Usuario creó un nuevo registro en Pedidos
301	Anónimo	127.0.0.1	2025-11-05 14:45:03.7966	CREACION	Usuario creó un nuevo registro en Pedidos
302	Anónimo	127.0.0.1	2025-11-05 14:45:21.619837	CREACION	Usuario creó un nuevo registro en Pedidos
303	Anónimo	127.0.0.1	2025-11-05 14:45:29.603309	CREACION	Usuario creó un nuevo registro en Pedidos
304	Anónimo	127.0.0.1	2025-11-05 14:45:47.077585	CREACION	Usuario creó un nuevo registro en Pedidos
305	Anónimo	127.0.0.1	2025-11-05 14:45:55.724806	CREACION	Usuario creó un nuevo registro en Pedidos
306	Anónimo	127.0.0.1	2025-11-05 14:46:18.347928	CREACION	Usuario creó un nuevo registro en Pedidos
307	Anónimo	127.0.0.1	2025-11-05 14:46:24.307283	CREACION	Usuario creó un nuevo registro en Pedidos
308	Anónimo	127.0.0.1	2025-11-05 14:46:45.896472	CREACION	Usuario creó un nuevo registro en Pedidos
309	Anónimo	127.0.0.1	2025-11-05 14:46:55.627226	CREACION	Usuario creó un nuevo registro en Pedidos
310	Anónimo	127.0.0.1	2025-11-05 14:47:08.20771	CREACION	Usuario creó un nuevo registro en Pedidos
311	Anónimo	127.0.0.1	2025-11-05 14:47:16.107424	CREACION	Usuario creó un nuevo registro en Pedidos
312	Anónimo	127.0.0.1	2025-11-05 14:47:35.102942	CREACION	Usuario creó un nuevo registro en Pedidos
313	Anónimo	127.0.0.1	2025-11-05 14:47:44.790147	CREACION	Usuario creó un nuevo registro en Pedidos
314	Anónimo	127.0.0.1	2025-11-05 14:48:05.535216	CREACION	Usuario creó un nuevo registro en Pedidos
315	Anónimo	127.0.0.1	2025-11-05 14:48:10.710204	CREACION	Usuario creó un nuevo registro en Pedidos
316	Anónimo	127.0.0.1	2025-11-05 14:48:26.186494	CREACION	Usuario creó un nuevo registro en Pedidos
317	Anónimo	127.0.0.1	2025-11-05 14:48:32.302602	CREACION	Usuario creó un nuevo registro en Pedidos
318	Anónimo	127.0.0.1	2025-11-05 14:48:58.216148	CREACION	Usuario creó un nuevo registro en Pedidos
319	Anónimo	127.0.0.1	2025-11-05 14:49:05.490036	CREACION	Usuario creó un nuevo registro en Pedidos
320	Anónimo	127.0.0.1	2025-11-05 14:49:19.490849	CREACION	Usuario creó un nuevo registro en Pedidos
321	Anónimo	127.0.0.1	2025-11-05 14:49:25.787259	CREACION	Usuario creó un nuevo registro en Pedidos
322	Anónimo	127.0.0.1	2025-11-05 14:49:43.345199	CREACION	Usuario creó un nuevo registro en Pedidos
323	Anónimo	127.0.0.1	2025-11-05 14:49:53.53422	CREACION	Usuario creó un nuevo registro en Pedidos
324	Anónimo	127.0.0.1	2025-11-05 14:50:06.704671	CREACION	Usuario creó un nuevo registro en Pedidos
325	Anónimo	127.0.0.1	2025-11-05 14:50:16.247273	CREACION	Usuario creó un nuevo registro en Pedidos
326	Anónimo	127.0.0.1	2025-11-05 15:54:24.427116	CREACION	Usuario creó un nuevo registro en Facturas
327	Anónimo	127.0.0.1	2025-11-05 15:55:58.585869	CREACION	Usuario creó un nuevo registro en Facturas
328	Anónimo	127.0.0.1	2025-11-05 15:55:58.644969	CREACION	Usuario creó un nuevo registro en Facturas
329	Anónimo	127.0.0.1	2025-11-05 15:55:58.729256	CREACION	Usuario creó un nuevo registro en Facturas
330	Anónimo	127.0.0.1	2025-11-05 15:55:58.987337	CREACION	Usuario creó un nuevo registro en Facturas
331	Anónimo	127.0.0.1	2025-11-05 15:56:00.871835	CREACION	Usuario creó un nuevo registro en Facturas
332	copa3	127.0.0.1	2025-11-05 16:21:39.554594	INICIO_SESION	Usuario inició sesión en el sistema
333	Anónimo	127.0.0.1	2025-11-05 16:30:25.13763	CREACION	Usuario creó un nuevo registro en Facturas
334	Anónimo	127.0.0.1	2025-11-05 16:31:55.019659	CREACION	Usuario creó un nuevo registro en Facturas
335	Anónimo	127.0.0.1	2025-11-05 16:31:55.12483	CREACION	Usuario creó un nuevo registro en Facturas
336	Anónimo	127.0.0.1	2025-11-05 16:31:55.275037	CREACION	Usuario creó un nuevo registro en Facturas
337	Anónimo	127.0.0.1	2025-11-05 16:31:55.287961	CREACION	Usuario creó un nuevo registro en Facturas
338	Anónimo	127.0.0.1	2025-11-05 16:31:57.36784	CREACION	Usuario creó un nuevo registro en Facturas
339	copa3	127.0.0.1	2025-11-05 16:34:47.163886	INICIO_SESION	Usuario inició sesión en el sistema
340	copa3	127.0.0.1	2025-11-05 16:59:25.654119	INICIO_SESION	Usuario inició sesión en el sistema
341	Anónimo	127.0.0.1	2025-11-05 18:55:12.936861	CREACION	Usuario creó un nuevo registro en Predicciones
342	Anónimo	127.0.0.1	2025-11-05 19:14:26.605724	CREACION	Usuario creó un nuevo registro en Predicciones
343	copa3	127.0.0.1	2025-11-05 22:04:30.981235	INICIO_SESION	Usuario inició sesión en el sistema
344	copa3	127.0.0.1	2025-11-05 22:21:20.387283	CREACION	Usuario creó un nuevo registro en Br
345	copa3	127.0.0.1	2025-11-05 22:23:38.015254	CREACION	Usuario creó un nuevo registro en Br
346	copa3	127.0.0.1	2025-11-05 22:30:36.918996	CREACION	Usuario creó un nuevo registro en Pedidos
347	copa3	127.0.0.1	2025-11-05 22:30:37.245716	CREACION	Usuario creó un nuevo registro en Pedidos
348	Anónimo	127.0.0.1	2025-11-05 22:41:02.368658	CREACION	Usuario creó un nuevo registro en Predicciones
\.


--
-- TOC entry 5165 (class 0 OID 36162)
-- Dependencies: 265
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (id, nombre_completo, direccion, telefono, fecha_nacimiento, id_usuario, estado) FROM stdin;
1	Juan Pérez	Av. Bolívar 123	78945612	1995-05-20	6	activo
2	Carlos Mendoza López	Av. Los Olivos 123, Miraflores, Lima	+51 987654321	1985-03-15	7	activo
3	Ana García Torres	Calle Los Pinos 456, Surco, Lima	+51 987654322	1990-07-22	8	activo
4	Roberto Silva Mendoza	Jr. Union 789, San Isidro, Lima	+51 987654323	1988-11-08	9	activo
5	María Fernández Rojas	Av. Universitaria 2345, Lima	+51 987654324	2000-01-30	10	activo
6	Jorge Martínez Díaz	Mz. L Lote 15, Villa El Salvador, Lima	+51 987654325	1978-09-14	11	activo
7	Claudia Ramos Castro	Calle Schell 345, Miraflores, Lima	+51 987654326	1995-04-18	12	activo
8	Pablo Gómez Herrera	Av. La Mar 678, Miraflores, Lima	+51 987654327	1982-12-03	13	activo
9	Lucía Torres Vargas	Calle Bolívar 123, Barranco, Lima	+51 987654328	1992-06-25	14	activo
10	Miguel Ruiz Soto	Av. Túpac Amaru 234, Comas, Lima	+51 987654329	1987-08-11	15	activo
11	Andrea Castro Mendoza	Av. Angamos 456, Surquillo, Lima	+51 987654330	1991-02-28	16	activo
12	Diego Álvarez Paredes	Calle San Martín 789, San Borja, Lima	+51 987654331	1989-10-07	17	activo
13	Patricia Flores Ríos	Av. Arequipa 1234, Lince, Lima	+51 987654332	1975-05-19	18	activo
14	Óscar Díaz Romero	Jr. Carabaya 345, Cercado de Lima	+51 987654333	1993-03-12	19	activo
15	Silvia Huamán Quispe	Pasaje Los Jardines 67, La Molina, Lima	+51 987654334	1984-11-23	20	activo
16	Ricardo Medina Torres	Av. Javier Prado 1235, San Isidro, Lima	+51 987654335	1980-07-30	21	activo
\.


--
-- TOC entry 5131 (class 0 OID 35692)
-- Dependencies: 231
-- Data for Name: control_asistencia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.control_asistencia (id_control, fecha, hora_marcado, estado, id_personal, id_turno) FROM stdin;
1	2025-09-14	13:42:23.603966	Presente	1	1
2	2025-09-05	15:01:06.142909	Presente	1	1
\.


--
-- TOC entry 5133 (class 0 OID 35698)
-- Dependencies: 233
-- Data for Name: control_calidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.control_calidad (id_control, observaciones, resultado, fecha_hora, id_personal, id_trazabilidad) FROM stdin;
\.


--
-- TOC entry 5135 (class 0 OID 35704)
-- Dependencies: 235
-- Data for Name: detalle_nota_salida; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_nota_salida (id_detalle, id_salida, id_lote, nombre_materia_prima, cantidad, unidad_medida) FROM stdin;
2	2	4	Algodón Pima 30/1 - Negro	70.00	metros
3	2	12	Hilo de Poliéster Core Spun - Negro	5.00	unidad
4	3	7	Pique 100% Algodón - Blanco	120.00	metros
5	3	12	Hilo de Poliéster Core Spun - Negro	30.00	unidad
6	3	8	Hilo Overlock 100% Poliéster - Blanco	10.00	metros
7	4	7	Pique 100% Algodón - Blanco	2.00	metros
8	4	14	Etiqueta de Composición Tela - Blanco	1.00	metros
9	4	10	Hilo de Algodón 30/2 - Gris	3.00	metros
\.


--
-- TOC entry 5171 (class 0 OID 36519)
-- Dependencies: 271
-- Data for Name: detalle_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_pedido (id_detalle, id_pedido, tipo_prenda, cuello, manga, color, talla, material, cantidad, precio_unitario) FROM stdin;
1	1	polera	Polo	Larga	Rojo	L	Algodón 100%	100	20.99
2	1	polera	Polo	3/4	Amarillo	S	Dry-fit 100% poliéster	50	35.00
3	2	polera	cuello V	manga corta	Negro	M	Algodón 100%	2	55.79
4	3	polera	cuello redondo	manga corta	Azul marino	M	Algodón 100%	30	19.99
5	3	camisa	cuello con botones	manga larga	Blanco	L	Popelina de algodón	20	48.00
6	4	polera	cuello V	manga corta	Negro	S	Algodón 100%	50	18.99
7	4	polera	cuello redondo	manga corta	Gris	M	Algodón 100%	25	19.99
8	5	camisa	cuello mao	manga corta	Blanco	M	Algodón 100%	15	36.50
9	5	camisa	cuello con botones	manga larga	Negro	L	Popelina de algodón	10	48.00
10	6	polera	cuello V	manga corta	Rojo	L	Dry-fit 100% poliéster	12	37.00
11	6	polera	cuello redondo	manga corta	Negro	XL	Dry-fit 100% poliéster	8	38.00
12	7	polera	cuello polo	manga corta	Azul claro	M	Algodón 100%	40	26.50
13	7	polera	cuello V	manga corta	Verde	S	Algodón 100%	30	18.99
14	8	polera	cuello redondo	manga corta	Amarillo	M	Algodón 100%	25	19.99
15	8	polera	cuello redondo	manga corta	Amarillo	L	Algodón 100%	20	20.99
16	9	camisa	cuello con botones	manga corta	Marrón	M	Lino 100%	8	57.00
17	9	polera	cuello redondo	manga corta	Negro	S	Algodón 100%	12	18.99
18	10	polera	cuello polo	manga corta	Negro	L	Algodón pima	35	27.50
19	10	polera	cuello polo	manga corta	Blanco	M	Algodón pima	25	26.50
20	11	polera	cuello redondo	manga corta	Verde	M	Algodón 100%	60	19.99
21	11	polera	cuello redondo	manga corta	Verde	L	Algodón 100%	40	20.99
22	12	polera	cuello V	manga corta	Rosa	S	Algodón 100%	100	18.99
23	12	polera	cuello V	manga corta	Rosa	M	Algodón 100%	80	19.99
24	13	polera	cuello redondo	manga corta	Azul eléctrico	M	Algodón 100%	45	19.99
25	13	polera	cuello V	manga corta	Negro	L	Algodón 100%	25	20.99
26	14	polera	cuello polo	manga corta	Negro	M	Algodón pima	15	26.50
27	14	camisa	cuello mao	manga corta	Blanco hueso	S	Lino 100%	10	55.00
28	15	polera	cuello V	manga corta	Rojo	M	Algodón 100%	80	19.99
29	15	polera	cuello redondo	manga larga	Negro	L	Algodón 100%	60	20.99
30	16	polera	cuello redondo	manga corta	Verde	L	Algodón 100%	20	20.99
31	17	camisa	cuello con botones	manga larga	Azul claro	M	Popelina de algodón	18	46.50
32	17	camisa	cuello con botones	manga larga	Blanco	L	Popelina de algodón	12	48.00
33	17	camisa	cuello con botones	manga larga	Azul claro	M	Popelina de algodón	18	46.50
34	17	camisa	cuello con botones	manga larga	Blanco	L	Popelina de algodón	12	48.00
35	18	polera	cuello redondo	manga corta	Morado	S	Algodón 100%	50	18.99
36	18	polera	cuello redondo	manga corta	Morado	M	Algodón 100%	40	19.99
37	19	camisa	cuello con botones	manga larga	Blanco	M	Popelina de algodón	25	46.50
38	19	camisa	cuello con botones	manga larga	Azul marino	L	Popelina de algodón	15	48.00
39	20	polera	cuello polo	manga corta	Negro	M	Algodón pima	35	26.50
40	20	polera	cuello polo	manga corta	Blanco	L	Algodón pima	25	27.50
41	21	polera	cuello V	manga corta	Naranja	M	Dry-fit 100% poliéster	30	36.00
42	21	polera	cuello V	manga corta	Naranja	L	Dry-fit 100% poliéster	20	37.00
43	22	polera	cuello redondo	manga corta	Verde olivo	L	Algodón 100%	30	20.99
44	22	polera	cuello redondo	manga corta	Verde olivo	M	Algodón 100%	40	19.99
45	23	camisa	cuello con botones	manga larga	Blanco	M	Popelina de algodón	30	46.50
46	23	camisa	cuello con botones	manga larga	Azul claro	L	Popelina de algodón	20	48.00
47	24	polera	cuello redondo	manga corta	Azul marino	M	Algodón 100%	50	19.99
48	24	polera	cuello redondo	manga corta	Gris	L	Algodón 100%	30	20.99
49	25	camisa	cuello con botones	manga larga	Blanco	M	Popelina de algodón	25	46.50
50	25	camisa	cuello con botones	manga larga	Blanco	L	Popelina de algodón	15	48.00
51	26	polera	cuello polo	manga corta	Azul claro	M	Algodón pima	40	26.50
52	26	polera	cuello polo	manga corta	Azul claro	L	Algodón pima	25	27.50
53	27	polera	cuello redondo	manga corta	Rojo	S	Algodón 100%	35	18.99
54	27	polera	cuello redondo	manga corta	Rojo	M	Algodón 100%	25	19.99
55	28	polera	cuello redondo	manga corta	Naranja	L	Algodón 100%	45	20.99
56	28	polera	cuello redondo	manga corta	Naranja	XL	Algodón 100%	25	21.99
57	29	polera	cuello V	manga corta	Negro	M	Algodón pima	20	26.50
58	29	camisa	cuello con botones	manga larga	Negro	L	Popelina de algodón	15	48.00
59	30	polera	cuello redondo	manga corta	Amarillo	M	Algodón 100%	60	19.99
60	30	polera	cuello redondo	manga corta	Amarillo	L	Algodón 100%	40	20.99
61	31	polera	cuello redondo	manga corta	Naranja fluorescente	L	Algodón 100%	50	20.99
62	31	polera	cuello redondo	manga corta	Naranja fluorescente	XL	Algodón 100%	30	21.99
63	32	camisa	cuello mao	manga corta	Blanco	M	Lino 100%	12	57.00
64	32	polera	cuello redondo	manga corta	Verde menta	S	Algodón 100%	18	18.99
65	33	polera	Redondo	Corta	Amarillo	S	Algodón 100%	20	18.99
\.


--
-- TOC entry 5137 (class 0 OID 35708)
-- Dependencies: 237
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
\.


--
-- TOC entry 5139 (class 0 OID 35715)
-- Dependencies: 239
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	permission
3	auth	group
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	usuarios	usurios
8	personal	empleado
9	personal	personal
10	turnos	turnos
\.


--
-- TOC entry 5141 (class 0 OID 35719)
-- Dependencies: 241
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2025-09-07 17:25:13.325873-04
2	auth	0001_initial	2025-09-07 17:25:13.446895-04
3	admin	0001_initial	2025-09-07 17:25:13.481711-04
4	admin	0002_logentry_remove_auto_add	2025-09-07 17:25:13.501164-04
5	admin	0003_logentry_add_action_flag_choices	2025-09-07 17:25:13.521095-04
6	contenttypes	0002_remove_content_type_name	2025-09-07 17:25:13.545938-04
7	auth	0002_alter_permission_name_max_length	2025-09-07 17:25:13.562223-04
8	auth	0003_alter_user_email_max_length	2025-09-07 17:25:13.583138-04
9	auth	0004_alter_user_username_opts	2025-09-07 17:25:13.59716-04
10	auth	0005_alter_user_last_login_null	2025-09-07 17:25:13.61227-04
11	auth	0006_require_contenttypes_0002	2025-09-07 17:25:13.614115-04
12	auth	0007_alter_validators_add_error_messages	2025-09-07 17:25:13.631086-04
13	auth	0008_alter_user_username_max_length	2025-09-07 17:25:13.662542-04
14	auth	0009_alter_user_last_name_max_length	2025-09-07 17:25:13.682259-04
15	auth	0010_alter_group_name_max_length	2025-09-07 17:25:13.703571-04
16	auth	0011_update_proxy_permissions	2025-09-07 17:25:13.716603-04
17	auth	0012_alter_user_first_name_max_length	2025-09-07 17:25:13.743925-04
18	personal	0001_initial	2025-09-07 17:25:13.747451-04
19	sessions	0001_initial	2025-09-07 17:25:13.77076-04
20	usuarios	0001_initial	2025-09-07 17:25:13.774362-04
21	personal	0002_alter_empleado_table	2025-09-07 18:52:04.946527-04
22	turnos	0001_initial	2025-09-13 00:03:12.299135-04
\.


--
-- TOC entry 5143 (class 0 OID 35725)
-- Dependencies: 243
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
\.


--
-- TOC entry 5173 (class 0 OID 36536)
-- Dependencies: 273
-- Data for Name: facturas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.facturas (id_factura, id_pedido, cod_factura, fecha_creacion, monto_total, stripe_payment_intent_id, stripe_checkout_session_id, estado_pago, metodo_pago, fecha_pago, codigo_autorizacion, ultimos_digitos_tarjeta, tipo_tarjeta) FROM stdin;
1	2	FAC-BED5434C	2025-11-05 07:46:57.478425	111.58	\N	cs_test_a1bJ11zQG4y8JBTNZWLBwaF25P5s46ZX0kvPrJ9mWc3VIUH0LqacW3q77E	pendiente	\N	\N	\N	\N	\N
2	1	FAC-DC337DF9	2025-11-05 15:54:22.070448	2099.00	pi_3SQ93xRzbD7AnJac1X0SSRLC	cs_test_b1Q4gKpg6x2XHp91wVVhI3a6oDTGnGlhsGEx1UN38dAR9x3ELVoldXoVOs	completado	tarjeta	2025-11-05 15:55:58.941697	\N	\N	\N
3	3	FAC-727789E0	2025-11-05 16:30:23.518575	1559.70	pi_3SQ9ckRzbD7AnJac0aV4ms4m	cs_test_b1qkq7mtFyw3uFGiOaZ2huSAAfBcjcW1Xf8PjNev412X4zocO5GnroJtF1	completado	tarjeta	2025-11-05 16:31:55.26621	\N	\N	\N
4	4	FAC-8A3B4C5D	2024-07-08 14:20:00	1948.45	pi_3SQ9dxRzbD7AnJac1a2b3c4d	cs_test_c1d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0	completado	tarjeta	2024-07-09 10:15:22	A12345	4242	visa
5	5	FAC-9B4C5D6E	2024-07-12 09:30:00	1027.50	pi_3SQ9exRzbD7AnJac2b3c4d5e	cs_test_d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1	completado	tarjeta	2024-07-13 11:45:33	A12346	4242	visa
6	6	FAC-1C5D6E7F	2024-07-15 16:45:00	814.00	pi_3SQ9fxRzbD7AnJac3c4d5e6f	cs_test_e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2	completado	tarjeta	2024-07-16 14:20:15	A12347	4242	visa
7	7	FAC-2D6E7F8G	2024-07-18 11:15:00	1849.50	pi_3SQ9gxRzbD7AnJac4d5e6f7g	cs_test_f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3	completado	tarjeta	2024-07-19 09:30:44	A12348	4242	visa
8	8	FAC-3E7F8G9H	2024-07-22 13:20:00	929.75	pi_3SQ9hxRzbD7AnJac5e6f7g8h	cs_test_g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4	completado	tarjeta	2024-07-23 16:10:28	A12349	4242	visa
9	9	FAC-4F8G9H0I	2024-07-25 10:45:00	741.88	pi_3SQ9ixRzbD7AnJac6f7g8h9i	cs_test_h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5	completado	tarjeta	2024-07-26 12:25:19	A12350	4242	visa
10	10	FAC-5G9H0I1J	2024-07-28 15:30:00	1712.50	pi_3SQ9jxRzbD7AnJac7g8h9i0j	cs_test_i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6	completado	tarjeta	2024-07-29 08:45:37	A12351	4242	visa
11	11	FAC-6H0I1J2K	2024-07-30 12:10:00	2098.80	pi_3SQ9kxRzbD7AnJac8h9i0j1k	cs_test_j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7	pendiente	\N	\N	\N	\N	\N
12	12	FAC-7I1J2K3L	2024-07-31 17:25:00	3419.40	pi_3SQ9lxRzbD7AnJac9i0j1k2l	cs_test_k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8	completado	tarjeta	2024-08-01 10:15:42	A12352	4242	visa
13	13	FAC-8J2K3L4M	2024-08-03 09:15:00	1448.30	pi_3SQ9mxRzbD7AnJac0j1k2l3m	cs_test_l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9	completado	tarjeta	2024-08-04 14:30:18	A12353	4242	visa
14	14	FAC-9K3L4M5N	2024-08-07 11:40:00	897.50	pi_3SQ9nxRzbD7AnJac1k2l3m4n	cs_test_m1n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0	completado	tarjeta	2024-08-08 13:20:55	A12354	4242	visa
15	15	FAC-1L4M5N6O	2024-08-10 14:55:00	2937.80	pi_3SQ9oxRzbD7AnJac2l3m4n5o	cs_test_n2o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1	completado	tarjeta	2024-08-11 16:45:33	A12355	4242	visa
16	16	FAC-2M5N6O7P	2024-08-14 10:20:00	999.70	pi_3SQ9pxRzbD7AnJac3m4n5o6p	cs_test_o3p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2	pendiente	\N	\N	\N	\N	\N
17	17	FAC-3N6O7P8Q	2024-08-16 13:35:00	1557.00	pi_3SQ9qxRzbD7AnJac4n5o6p7q	cs_test_p4q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3	completado	tarjeta	2024-08-17 11:10:47	A12356	4242	visa
18	18	FAC-4O7P8Q9R	2024-08-20 15:50:00	1349.30	pi_3SQ9rxRzbD7AnJac5o6p7q8r	cs_test_q5r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4	completado	tarjeta	2024-08-21 09:25:14	A12357	4242	visa
19	19	FAC-5P8Q9R0S	2024-08-22 12:05:00	1942.50	pi_3SQ9sxRzbD7AnJac6p7q8r9s	cs_test_r6s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5	completado	tarjeta	2024-08-23 14:40:29	A12358	4242	visa
20	20	FAC-6Q9R0S1T	2024-08-25 08:30:00	1707.50	pi_3SQ9txRzbD7AnJac7q8r9s0t	cs_test_s7t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6	completado	tarjeta	2024-08-26 17:15:38	A12359	4242	visa
21	21	FAC-7R0S1T2U	2024-08-28 16:40:00	1880.00	pi_3SQ9uxRzbD7AnJac8r9s0t1u	cs_test_t8u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7	pendiente	\N	\N	\N	\N	\N
22	22	FAC-8S1T2U3V	2024-08-30 11:25:00	1399.30	pi_3SQ9vxRzbD7AnJac9s0t1u2v	cs_test_u9v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8	completado	tarjeta	2024-08-31 13:50:21	A12360	4242	visa
23	23	FAC-9T2U3V4W	2024-09-02 14:15:00	2670.00	pi_3SQ9wxRzbD7AnJac0t1u2v3w	cs_test_v0w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9	completado	tarjeta	2024-09-03 10:35:44	A12361	4242	visa
24	24	FAC-1U3V4W5X	2024-09-05 09:50:00	1598.80	pi_3SQ9xxRzbD7AnJac1u2v3w4x	cs_test_w1x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0	pendiente	\N	\N	\N	\N	\N
25	25	FAC-2V4W5X6Y	2024-09-09 13:05:00	1785.00	pi_3SQ9yxRzbD7AnJac2v3w4x5y	cs_test_x2y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1	completado	tarjeta	2024-09-10 15:25:16	A12362	4242	visa
26	26	FAC-3W5X6Y7Z	2024-09-12 11:30:00	1852.50	pi_3SQ9zxRzbD7AnJac3w4x5y6z	cs_test_y3z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2	completado	tarjeta	2024-09-13 12:40:28	A12363	4242	visa
27	27	FAC-4X6Y7Z8A	2024-09-16 16:55:00	1119.40	pi_3SQA0xRzbD7AnJac4x5y6z7a	cs_test_z4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3	completado	tarjeta	2024-09-17 08:20:39	A12364	4242	visa
28	28	FAC-5Y7Z8A9B	2024-09-18 10:10:00	1569.80	pi_3SQA1xRzbD7AnJac5y6z7a8b	cs_test_a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4	pendiente	\N	\N	\N	\N	\N
29	29	FAC-6Z8A9B0C	2024-09-20 14:45:00	1235.00	pi_3SQA2xRzbD7AnJac6z7a8b9c	cs_test_b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4u5	completado	tarjeta	2024-09-21 11:55:47	A12365	4242	visa
30	30	FAC-7A9B0C1D	2024-09-23 12:20:00	1999.00	pi_3SQA3xRzbD7AnJac7a8b9c0d	cs_test_c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4u5v6	completado	tarjeta	2024-09-24 13:30:52	A12366	4242	visa
31	31	FAC-8B0C1D2E	2024-09-25 15:35:00	1748.80	pi_3SQA4xRzbD7AnJac8b9c0d1e	cs_test_d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4u5v6w7	pendiente	\N	\N	\N	\N	\N
32	32	FAC-9C1D2E3F	2024-09-28 09:40:00	1023.82	pi_3SQA5xRzbD7AnJac9c0d1e2f	cs_test_e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4u5v6w7x8	completado	tarjeta	2024-09-29 14:15:33	A12367	4242	visa
\.


--
-- TOC entry 5144 (class 0 OID 35730)
-- Dependencies: 244
-- Data for Name: inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventario (id_inventario, nombre_materia_prima, cantidad_actual, unidad_medida, ubicacion, estado, fecha_actualizacion, id_lote, stock_minimo) FROM stdin;
3	Algodón Pima 30/1 - Blanco	720.00	metros	Almacén Principal	Disponible	2025-10-20 18:03:51.993586	3	0.00
5	Jersey de Algodón 160 gsm - Azul Marino	350.00	metros	Almacén Principal	Disponible	2025-10-20 18:04:59.239399	6	0.00
8	Hilo de Algodón 30/2 - Blanco	50.00	metros	Almacén Principal	Disponible	2025-10-20 18:17:59.787066	9	0.00
10	Hilo de Poliéster Core Spun - Blanco	45.00	metros	Almacén Principal	Disponible	2025-10-20 18:20:53.277836	11	0.00
4	Algodón Pima 30/1 - Negro	230.00	metros	Almacén Principal	Disponible	2025-10-20 18:02:42.21552	4	0.00
12	Etiqueta Principal 100% Poliéster - Negro	50.00	kg	Almacén Principal	Disponible	2025-10-20 18:33:54.463263	13	0.00
14	French Terry 240 gsm - Gris Heather	60.00	kg	Almacén Principal	Disponible	2025-10-20 18:39:37.370832	15	0.00
15	Cinta Rib para Cuello - Blanco	67.00	kg	Almacén Principal	Disponible	2025-10-20 18:50:08.18931	16	0.00
11	Hilo de Poliéster Core Spun - Negro	20.00	unidad	Almacén Principal	Disponible	2025-10-20 18:22:11.085193	12	0.00
7	Hilo Overlock 100% Poliéster - Blanco	20.00	metros	Almacén Principal	Disponible	2025-10-20 18:08:22.264607	8	0.00
6	Pique 100% Algodón - Blanco	73.00	metros	Almacén Principal	Disponible	2025-10-20 18:06:00.492241	7	0.00
13	Etiqueta de Composición Tela - Blanco	49.00	metros	Almacén Principal	Disponible	2025-10-20 18:35:37.383749	14	0.00
9	Hilo de Algodón 30/2 - Gris	67.00	metros	Almacén Principal	Disponible	2025-10-20 18:19:34.964507	10	0.00
\.


--
-- TOC entry 5146 (class 0 OID 35736)
-- Dependencies: 246
-- Data for Name: lotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lotes (id_lote, codigo_lote, fecha_recepcion, cantidad, estado, id_materia) FROM stdin;
3	LT-ALG-BCO-2401	2025-09-20	450.00	Disponible	3
5	LT-JER-AZM-2403	2025-09-14	270.00	Disponible	3
6	LT-FTH-GRH-2404	2025-09-16	350.00	Disponible	5
9	HL-ALG-BLN-30/2	2025-09-25	50.00	Disponible	15
11	HL-POL-CR-SP-BLN	2025-09-15	45.00	Disponible	18
4	LT-ALG-NEG-2402	2025-09-10	230.00	Disponible	4
13	ET-PRCP-POL-NG-100	2025-09-12	50.00	Disponible	25
15	FR-TR-GSM-GR-HT-254	2025-10-02	60.00	Disponible	7
16	CNT-R-CLL-BLN-542	2025-10-19	67.00	Disponible	31
12	HL-POL-CR-SP-NGR	2025-09-28	20.00	Disponible	19
8	HL-OV-POL-BLN	2025-10-04	20.00	Disponible	20
7	LT-TRI-GRM-2405	2025-09-13	73.00	Disponible	9
14	ET-COMP-TL-BLN	2025-09-27	49.00	Disponible	26
10	HL-ALG-GR-30/2	2025-09-25	67.00	Disponible	17
\.


--
-- TOC entry 5148 (class 0 OID 35740)
-- Dependencies: 248
-- Data for Name: materias_primas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.materias_primas (id_materia, nombre, tipo_material) FROM stdin;
3	Algodón Pima 30/1 - Blanco	Tela
4	Algodón Pima 30/1 - Negro	Tela
5	Jersey de Algodón 160 gsm - Azul Marino	Tela
6	Jersey de Algodón 160 gsm - Rojo	Tela
7	French Terry 240 gsm - Gris Heather	Tela
8	French Terry 240 gsm - Verde Oliva	Tela
9	Pique 100% Algodón - Blanco	Tela
10	Pique 100% Algodón - Negro	Tela
11	Tela Triblend - Gris Melange	Tela
12	Tela Triblend - Marrón Claro	Tela
13	Jersey Mezclado 60/40 - Blanco	Tela
14	Jersey Mezclado 60/40 - Azul Real	Tela
15	Hilo de Algodón 30/2 - Blanco	Hilo
16	Hilo de Algodón 30/2 - Negro	Hilo
17	Hilo de Algodón 30/2 - Gris	Hilo
18	Hilo de Poliéster Core Spun - Blanco	Hilo
19	Hilo de Poliéster Core Spun - Negro	Hilo
20	Hilo Overlock 100% Poliéster - Blanco	Hilo
21	Hilo Overlock 100% Poliéster - Negro	Hilo
22	Hilo para Ojal 40/3 - Blanco	Hilo
23	Hilo para Ojal 40/3 - Negro	Hilo
24	Etiqueta Principal 100% Poliéster - Blanco	Etiqueta
25	Etiqueta Principal 100% Poliéster - Negro	Etiqueta
26	Etiqueta de Composición Tela - Blanco	Etiqueta
27	Etiqueta de Talla Satinada - Plata	Etiqueta
28	Etiqueta de Talla Satinada - Oro	Etiqueta
29	tiqueta de Cuidado Lavado - Blanco	Etiqueta
30	Cinta Rib para Cuello - Negro	Terminación
31	Cinta Rib para Cuello - Blanco	Terminación
32	Cinta Rib para Cuello - Gris	Terminación
33	Cinta para Hombros - Blanco	Terminación
34	Elástico para Puños - Negro	Terminación
35	Elástico para Puños - Blanco	Terminación
36	Botones Plásticos 14mm - Blanco	Terminación
37	Botones Plásticos 14mm - Negro	Terminación
38	Botones Plásticos 14mm - Natural	Terminación
39	Tinta Plastisol - Blanco	Estampado
40	Tinta Plastisol - Rojo Intenso	Estampado
41	Tinta Plastisol - Azul Real	Estampado
42	Tinta Plastisol - Negro	Estampado
43	Tinta Plastisol - Amarillo Fluorescente	Estampado
44	Tinta Plastisol - Verde Lima	Estampado
45	Tinta al Agua Base - Transparente	Estampado
46	Bolsa Plástica Individual - Transparente	Embalaje
47	Bolsa Plástica Individual - Negra	Embalaje
48	Caja de Cartón 30x40cm - Kraft Natural	Embalaje
49	Caja de Cartón 30x40cm - Blanco	Embalaje
50	Sticker de Identificación - Blanco	Embalaje
51	Gancho para Colgar Prendas - Transparente	Embalaje
52	Gancho para Colgar Prendas - Negro	Embalaje
\.


--
-- TOC entry 5175 (class 0 OID 36554)
-- Dependencies: 275
-- Data for Name: modelos_prediccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modelos_prediccion (id_modelo, nombre_modelo, tipo_modelo, "precision", fecha_entrenamiento, parametros, activo) FROM stdin;
1	Modelo_random_forest_20251105_144808	random_forest	0.86	2025-11-05 18:48:08.903278	{"max_depth": 10, "n_estimators": 100}	t
2	Modelo_random_forest_20251105_145512	random_forest	0.86	2025-11-05 18:55:12.934281	{"max_depth": 10, "n_estimators": 100}	t
\.


--
-- TOC entry 5150 (class 0 OID 35744)
-- Dependencies: 250
-- Data for Name: nota_salida; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nota_salida (id_salida, fecha_salida, motivo, estado, id_personal) FROM stdin;
2	2025-10-20	Producción: Polera - OP20251020-558	Completado	2
3	2025-10-20	Producción: Camisa - OP20251020-605	Completado	3
4	2025-10-20	Producción: Camisa - OP20251020-886	Completado	1
\.


--
-- TOC entry 5152 (class 0 OID 35750)
-- Dependencies: 252
-- Data for Name: orden_produccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orden_produccion (id_orden, cod_orden, fecha_inicio, fecha_fin, fecha_entrega, estado, producto_modelo, color, talla, cantidad_total, id_personal) FROM stdin;
2	OP20251020-558	2025-10-03	2025-10-10	2025-10-14	En Proceso	Polera	Negro	L	50	2
3	OP20251020-605	2025-10-03	2025-10-10	2025-10-14	En Proceso	Camisa	Blanco	M	100	3
4	OP20251020-886	2025-09-24	2025-09-30	2025-10-10	En Proceso	Camisa	Blanco	M	50	1
\.


--
-- TOC entry 5169 (class 0 OID 36501)
-- Dependencies: 269
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (id_pedido, cod_pedido, fecha_pedido, fecha_entrega_prometida, estado, id_cliente, total, observaciones, fecha_creacion) FROM stdin;
25	PED-624D591C	2025-11-05 14:14:25.056761	2025-10-05	en_produccion	8	1882.50	Uniforme para personal de recepción	2025-09-09
1	PED-AAD93F51	2025-11-05 05:42:44.366668	2025-11-02	cotizacion	1	2099.00		2025-11-05
2	PED-9482B531	2025-11-05 07:37:18.053234	2024-12-30	cotizacion	1	111.58	Pedido de prueba con Stripe	2025-11-05
14	PED-D079E075	2025-11-05 14:10:32.822195	2025-09-15	completado	9	947.50	Poleras para equipo creativo - diseño exclusivo	2025-08-07
3	PED-8B393097	2025-11-05 14:05:10.588942	2024-08-15	entregado	2	1559.70	Uniformes corporativos para equipo de ventas	2024-07-05
4	PED-9A01E684	2025-11-05 14:05:45.346185	2025-08-10	entregado	4	1449.25	Merchandising para evento de inversores	2025-07-08
15	PED-645ED809	2025-11-05 14:10:56.155512	2025-09-10	completado	14	2858.60	Merchandising para gira nacional	2025-08-10
5	PED-CE6EEC59	2025-11-05 14:06:03.403276	2025-07-30	entregado	8	1027.50	Uniforme para personal de cocina y meseros	2025-07-12
16	PED-7164BFE8	2025-11-05 14:11:10.55713	2025-09-05	completado	6	419.80	Poleras promocionales para apertura de local	2025-08-14
6	PED-EBCE85C7	2025-11-05 14:06:31.401734	2025-08-20	entregado	11	748.00	Poleras deportivas para instructores	2025-07-15
26	PED-FF84449A	2025-11-05 14:14:43.817685	2025-10-20	confirmado	12	1747.50	Poleras para personal administrativo	2025-09-12
7	PED-C7292076	2025-11-05 14:06:52.025399	2025-08-25	entregado	12	1629.70	Poleras para campaña de lanzamiento	2025-07-18
8	PED-8FBC1FDB	2025-11-05 14:07:12.320265	2025-08-05	entregado	13	919.55	Uniforme deportivo para equipo de básquet	2025-07-22
27	PED-4BC93F92	2025-11-05 14:15:01.369369	2025-10-08	confirmado	13	1164.40	Poleras para profesores y estudiantes	2025-09-16
9	PED-14C1C39D	2025-11-05 14:07:33.087263	2025-08-01	entregado	15	683.88	Delantales y poleras para baristas	2025-07-25
17	PED-52126442	2025-11-05 14:11:25.840439	2025-09-25	completado	3	2826.00	Uniforme completo para personal administrativo	2025-08-16
10	PED-705E07E8	2025-11-05 14:08:01.408751	2025-08-30	entregado	16	1625.00	Poleras para staff de conferencia anual	2025-07-28
11	PED-3EE2BB1B	2025-11-05 14:09:25.209395	2025-08-18	entregado	10	2039.00	Poleras para voluntarios - campaña social	2025-07-30
18	PED-72746D69	2025-11-05 14:11:40.18571	2025-09-18	completado	5	1749.10	Poleras para semana de ingeniería	2025-08-20
12	PED-97254A94	2025-11-05 14:09:48.041131	2025-08-12	entregado	7	3498.20	Colección limitada para seguidores premium	2025-07-31
28	PED-3B27F463	2025-11-05 14:15:16.834787	2025-10-25	confirmado	16	1494.30	Uniforme para equipo de almacén	2025-09-18
13	PED-BEFFD483	2025-11-05 14:10:09.078447	2025-09-20	completado	4	1424.30	Poleras para hackathon interno	2025-08-03
19	PED-CA93D3B1	2025-11-05 14:11:56.853547	2025-09-30	completado	2	1882.50	Camisas formales para equipo de consultores	2025-08-22
20	PED-F7DAB6E5	2025-11-05 14:12:12.40518	2025-09-12	completado	3	1615.00	Uniforme para vendedores - temporada alta	2025-08-25
29	PED-7392EDC5	2025-11-05 14:15:46.00278	2025-10-12	confirmado	9	1250.00	Poleras para equipo creativo - sesión especial	2025-09-20
21	PED-B5532F35	2025-11-05 14:12:32.297497	2025-09-08	completado	11	1820.00	Poleras para equipo de running	2025-08-28
22	PED-563D1965	2025-11-05 14:12:47.532215	2025-09-22	completado	10	1429.30	Poleras para miembros de la cooperativa	2025-08-30
30	PED-9662C189	2025-11-05 14:16:03.495643	2025-10-18	confirmado	10	2039.00	Poleras para festival cultural	2025-09-23
23	PED-38C4A284	2025-11-05 14:13:08.220357	2025-10-15	en_produccion	2	2355.00	Camisas para equipo ejecutivo	2025-09-02
24	PED-6975E37B	2025-11-05 14:13:27.967934	2025-10-10	en_produccion	4	1629.20	Poleras para equipo de logística	2025-09-05
31	PED-3FF09E95	2025-11-05 14:17:48.754731	2025-10-30	cotizacion	6	1709.20	Poleras para equipo de obra	2025-09-25
32	PED-B1A3053B	2025-11-05 14:18:03.463637	2025-10-22	cotizacion	15	1025.82	Uniforme para terapeutas y recepcionistas	2025-09-28
33	PED-9C268883	2025-11-05 22:30:36.90542	2025-11-29	cotizacion	3	379.80	prueba	2025-11-05
\.


--
-- TOC entry 5154 (class 0 OID 35757)
-- Dependencies: 254
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permisos (id_permiso, id_user, insertar, editar, eliminar, ver, vista) FROM stdin;
4	1	t	t	t	t	Personal
6	1	t	t	t	t	Usuarios
7	1	t	t	t	t	Inventario
8	1	t	t	t	t	Bitacora
9	1	t	t	t	t	Lotes
10	1	t	t	t	t	OrdenProduccion
11	1	t	t	t	t	NotaSalida
12	5	t	t	t	t	OrdenProduccion
13	5	t	t	t	t	NotaSalida
14	5	t	t	t	t	Bitacora
15	5	t	t	t	t	Usuarios
16	1	t	t	t	t	Clientes
\.


--
-- TOC entry 5156 (class 0 OID 35767)
-- Dependencies: 256
-- Data for Name: personal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal (id, nombre_completo, direccion, telefono, rol, fecha_nacimiento, id_usuario, estado) FROM stdin;
2	Juan Manuel Matienzo Flores	AV. Santos Dumonts, 4to Anillo	68450024	Administrador	2003-07-17	2	activo
3	Jerson Alexander Moreno Gonzales	2do Anillo	65524100	Administrador	2002-03-22	3	activo
4	Isaac Orellana Escobar	2do anillo, parque urbano	64452789	Administrador	2004-09-20	4	activo
5	Mario Robles	2do anillo, Av. bush	61154111	Administrador	2002-07-25	5	activo
1	D’alessandro Copa Monzon	Av. 16 de noviembre	67762111	Administrador	2001-11-12	1	activo
\.


--
-- TOC entry 5167 (class 0 OID 36196)
-- Dependencies: 267
-- Data for Name: precios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.precios (id_precio, decripcion, material, talla, precio_base, activo) FROM stdin;
1	Polera básica	Algodón 100%	S	18.99	t
2	Polera básica	Algodón 100%	M	19.99	t
3	Polera básica	Algodón 100%	L	20.99	t
4	Polera básica	Algodón 100%	XL	21.99	t
5	Polera premium	Algodón pima	S	25.50	t
6	Polera premium	Algodón pima	M	26.50	t
7	Polera premium	Algodón pima	L	27.50	t
8	Polera premium	Algodón pima	XL	28.50	t
9	Polera deportiva	Algodón 60% - Poliéster 40%	S	22.75	t
10	Polera deportiva	Algodón 60% - Poliéster 40%	M	23.75	t
11	Polera deportiva	Algodón 60% - Poliéster 40%	L	24.75	t
12	Polera deportiva	Algodón 60% - Poliéster 40%	XL	25.75	t
13	Polera técnica	Dry-fit 100% poliéster	S	35.00	t
14	Polera técnica	Dry-fit 100% poliéster	M	36.00	t
15	Polera técnica	Dry-fit 100% poliéster	L	37.00	t
16	Polera técnica	Dry-fit 100% poliéster	XL	38.00	t
17	Camisa casual	Algodón 100%	S	35.00	t
18	Camisa casual	Algodón 100%	M	36.50	t
19	Camisa casual	Algodón 100%	L	38.00	t
20	Camisa casual	Algodón 100%	XL	39.50	t
21	Camisa formal	Popelina de algodón	S	45.00	t
22	Camisa formal	Popelina de algodón	M	46.50	t
23	Camisa formal	Popelina de algodón	L	48.00	t
24	Camisa formal	Popelina de algodón	XL	49.50	t
25	Camisa de lino	Lino 100%	S	55.00	t
26	Camisa de lino	Lino 100%	M	57.00	t
27	Camisa de lino	Lino 100%	L	59.00	t
28	Camisa de lino	Lino 100%	XL	61.00	t
29	Camisa polo	Tela pique algodón	S	42.00	t
30	Camisa polo	Tela pique algodón	M	43.50	t
31	Camisa polo	Tela pique algodón	L	45.00	t
32	Camisa polo	Tela pique algodón	XL	46.50	t
33	Recargo cuello V	Algodón estándar	\N	4.99	t
34	Recargo cuello con botones	Algodón estándar	\N	5.50	t
35	Recargo cuello polo	Algodón estándar	\N	6.25	t
36	Recargo cuello mao	Algodón estándar	\N	7.00	t
37	Recargo manga corta	Algodón estándar	\N	3.50	t
38	Recargo manga larga	Algodón estándar	\N	5.00	t
39	Recargo manga 3/4	Algodón estándar	\N	4.25	t
40	Recargo manga raglán	Algodón estándar	\N	6.75	t
\.


--
-- TOC entry 5177 (class 0 OID 36565)
-- Dependencies: 277
-- Data for Name: predicciones_pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predicciones_pedidos (id_prediccion, id_modelo, fecha_prediccion, cantidad_predicha, monto_predicho, intervalo_confianza, fecha_creacion) FROM stdin;
1	1	2025-12-05	15	26250.00	1.00	2025-11-05 19:14:26.591983
2	1	2026-01-04	17	28940.62	0.98	2025-11-05 19:14:26.600539
3	1	2026-02-03	18	31446.96	0.96	2025-11-05 19:14:26.601546
4	1	2026-03-05	20	33426.42	0.94	2025-11-05 19:14:26.602487
5	1	2026-04-04	20	34670.27	0.92	2025-11-05 19:14:26.603398
6	1	2026-05-04	21	35177.51	0.90	2025-11-05 19:14:26.604279
7	1	2025-12-05	15	26250.00	1.00	2025-11-05 22:41:02.340963
8	1	2026-01-04	17	28940.62	0.98	2025-11-05 22:41:02.360105
9	1	2026-02-03	18	31446.96	0.96	2025-11-05 22:41:02.362275
\.


--
-- TOC entry 5158 (class 0 OID 35771)
-- Dependencies: 258
-- Data for Name: trazabilidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trazabilidad (id_trazabilidad, proceso, descripcion_proceso, fecha_registro, hora_inicio, hora_fin, cantidad, estado, id_personal, id_orden) FROM stdin;
2	Consumo de Materia Prima - Algodón Pima 30/1 - Negro	Se consumió 70.00 metros de Algodón Pima 30/1 - Negro para la producción de 50 unidades de Polera (Negro/L). Material extraído de 1 lote(s): Lote LT-ALG-NEG-2402: 70.0 metros. Responsable: Juan Manuel Matienzo Flores.	2025-10-20	18:29:50.443966	18:29:50.443966	70	Completado	2	2
3	Consumo de Materia Prima - Hilo de Poliéster Core Spun - Negro	Se consumió 5.00 unidad de Hilo de Poliéster Core Spun - Negro para la producción de 50 unidades de Polera (Negro/L). Material extraído de 1 lote(s): Lote HL-POL-CR-SP-NGR: 5.0 unidad. Responsable: Juan Manuel Matienzo Flores.	2025-10-20	18:29:50.459666	18:29:50.459666	5	Completado	2	2
4	Consumo de Materia Prima - Pique 100% Algodón - Blanco	Se consumió 120.00 metros de Pique 100% Algodón - Blanco para la producción de 100 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote LT-TRI-GRM-2405: 120.0 metros. Responsable: Jerson Alexander Moreno Gonzales.	2025-10-20	18:52:25.405795	18:52:25.405795	120	Completado	3	3
5	Consumo de Materia Prima - Hilo de Poliéster Core Spun - Negro	Se consumió 30.00 unidad de Hilo de Poliéster Core Spun - Negro para la producción de 100 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote HL-POL-CR-SP-NGR: 30.0 unidad. Responsable: Jerson Alexander Moreno Gonzales.	2025-10-20	18:52:25.415837	18:52:25.415837	30	Completado	3	3
6	Consumo de Materia Prima - Hilo Overlock 100% Poliéster - Blanco	Se consumió 10.00 metros de Hilo Overlock 100% Poliéster - Blanco para la producción de 100 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote HL-OV-POL-BLN: 10.0 metros. Responsable: Jerson Alexander Moreno Gonzales.	2025-10-20	18:52:25.428057	18:52:25.428057	10	Completado	3	3
7	Consumo de Materia Prima - Pique 100% Algodón - Blanco	Se consumió 2.00 metros de Pique 100% Algodón - Blanco para la producción de 50 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote LT-TRI-GRM-2405: 2.0 metros. Responsable: D’alessandro Copa Monzon.	2025-10-20	22:17:39.964221	22:17:39.964221	2	Completado	1	4
8	Consumo de Materia Prima - Etiqueta de Composición Tela - Blanco	Se consumió 1.00 metros de Etiqueta de Composición Tela - Blanco para la producción de 50 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote ET-COMP-TL-BLN: 1.0 metros. Responsable: D’alessandro Copa Monzon.	2025-10-20	22:17:39.985124	22:17:39.985124	1	Completado	1	4
9	Consumo de Materia Prima - Hilo de Algodón 30/2 - Gris	Se consumió 3.00 metros de Hilo de Algodón 30/2 - Gris para la producción de 50 unidades de Camisa (Blanco/M). Material extraído de 1 lote(s): Lote HL-ALG-GR-30/2: 3.0 metros. Responsable: D’alessandro Copa Monzon.	2025-10-20	22:17:40.008633	22:17:40.008633	3	Completado	1	4
\.


--
-- TOC entry 5160 (class 0 OID 35777)
-- Dependencies: 260
-- Data for Name: turnos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.turnos (id, turno, hora_entrada, hora_salida, estado) FROM stdin;
1	mañana	07:00:00	15:00:00	activo
8	tarde	15:00:00	23:00:00	activo
\.


--
-- TOC entry 5162 (class 0 OID 35781)
-- Dependencies: 262
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, name_user, email, password, tipo_usuario, estado) FROM stdin;
2	manu3	ejemplo1@gmail.com	pbkdf2_sha256$1000000$kh25n6qhegePBLANUpC8cQ$Sr5XLEzwwpacWUd1CLvtGPgQHXRTPt1Q59I+nrRdi8M=	empleado	activo
4	isaac3	isaacorellana@gmail.com	pbkdf2_sha256$1000000$KI0rQRH8EM2bM8jIq3P1SM$7KjsOzc3HcXmv8xd6kKndN+N+osisWBAfYEgwDOUDZI=	empleado	Activo
3	jerson33	jerson045@gmail.com	pbkdf2_sha256$1000000$R14Taj3P8m4PtfuUeZ1YDs$vPN+FbAsoOdDUMvaRnAQQlHFfYqzUZVz/IbWqGAYFM4=	admin	Activo
5	mario3	mario544@gmail.com	pbkdf2_sha256$1000000$wkvKEtaTFZ0yoiKEfKDuWl$mf43riWZ1jGIuNuEy1YGlvnpbExNCmPRhpvbASlM9XM=	admin	Activo
1	copa3	ejemplo22@gmail.com	pbkdf2_sha256$1000000$pWpSe23E4hQNfuGSQHiE5e$t/20Z2BTuRNONiklvFhSVaB3i8+9cycMgRd+Dj6555M=	admin	activo
6	juan3	juan@email.com	pbkdf2_sha256$1000000$GU3ELVhy2XnHLCFAaelnhi$sOqt5VrSC1wCajAXXqQbmfQzTLnMI6Wlkhi2dViLldc=	cliente	activo
7	carlos_mendoza	carlos.mendoza@empresa.com	pbkdf2_sha256$1000000$xaLIveksQd5tYrZh1aNQ53$Ic6Qm46D5gtOmzSgKqDDVeLimkuQ8CfzQlG5AB3IBVQ=	cliente	activo
8	ana_garcia	ana.garcia@tienda.com	pbkdf2_sha256$1000000$vm56R1eGsLSaNSzNQZfBXM$tchzSUAUugrnVcdyQeARQ57itWP21Ym0THSiQzvUFLM=	cliente	activo
9	roberto_silva	roberto@techstartup.com	pbkdf2_sha256$1000000$mAxqFiDV20qssQJftUIKbD$BhVqQIGIKAfCq3mAopdVSVNW2ubRYMmAt1/8dkmLrpQ=	cliente	activo
10	maria_fernandez	maria.fernandez@universidad.edu.pe	pbkdf2_sha256$1000000$rhg7gC9D5MebhTGNrfAgYf$oDkbQ5DGTfIfnwjEVLEj0JSBJ0shEdFAz29v8BiRSmY=	cliente	activo
11	jorge_martinez	jorge@negociofam.com	pbkdf2_sha256$1000000$1Tiur2LXqnZeoDtniCIkNt$bL+rhKGmRBxcU47jpjaMUBcG8TmsXk/WFnXD8nBUIjs=	cliente	activo
12	claudia_ramos	claudia.ramos@influencer.com	pbkdf2_sha256$1000000$2sK6vz50rY0P0tXmTFDMls$QwP4g3+YAzVSEH66n7qwFiOIpIC7YGhiCRm1oUnX7B4=	cliente	activo
13	pablo_gomez	pablo@restaurant.com	pbkdf2_sha256$1000000$g2wUYURwSGejQf6Pu9Ei43$iwl+MAKCWKcR0qj4r9HzEunvEz+IVBvQvspGoYeODEE=	cliente	activo
14	lucia_torres	lucia@disenio.com	pbkdf2_sha256$1000000$lf8SplOLrL4Zpu6kGabO9N$2bmkCOLfQ+fHCBs0un5rh44GLjyNtJZqOI5CU6mwH8c=	cliente	activo
15	miguel_ruiz	miguel@ongcomunidad.org	pbkdf2_sha256$1000000$JXV5mRy5yGNKYaNpQTcdN2$nnp0A8/oyV+dnNXPBRA9IQivVdG1DNJ9cZc4t8x/ZU8=	cliente	activo
16	andrea_castro	andrea@gimnasiofit.com	pbkdf2_sha256$1000000$9rrJQCVcfdiEPQjJNYWEEU$j3f5PotAnDh+vRjX43BImHKRG7iROs1cuF7ojAoOW7Y=	cliente	activo
17	diego_alvarez	diego@marketingdigital.com	pbkdf2_sha256$1000000$MKpj0c2wcZCdObJre8Fn5T$zrw1Zmp2Y+Tm24Z5FAL06SjGluI0BF5ujYyhTqrRBqU=	cliente	activo
18	patricia_flores	patricia@colegio.edu.pe	pbkdf2_sha256$1000000$ABQ3jeuKPvt4uOX7eqPiie$QG4emmCSfQp+iuzyyuGrWgTnUwO7wzbh869CduNPtwQ=	cliente	activo
19	oscar_diaz	oscar@bandamusical.com	pbkdf2_sha256$1000000$NUC6QLUEMOmvNvNkRv4pAv$wowjumdIH6F5WlE5NMr41o39eX9uSKcBAGgdPGJmUSI=	cliente	activo
20	silvia_huaman	silvia@cafeteria.com	pbkdf2_sha256$1000000$tk1fGAv8mjg7rPxbUJ3JkG$d8y5InTLglqy8nFtEOuTtGZFqi8HXb402Pvzf0q5uIg=	cliente	activo
21	ricardo_medina	ricardo@eventoscorp.com	pbkdf2_sha256$1000000$3DOoGuQIqOqifnwGd2CG68$FA9yUyrQOwISsTPdSxvzDw4abeweq6V0GHvXLzV4Lqw=	cliente	activo
\.


--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 218
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 220
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 222
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 40, true);


--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 225
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 226
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, false);


--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 228
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 230
-- Name: bitacora_id_bitacora_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bitacora_id_bitacora_seq', 348, true);


--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 264
-- Name: clientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_id_seq', 16, true);


--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 232
-- Name: control_asistencia_id_control_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.control_asistencia_id_control_seq', 2, true);


--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 234
-- Name: control_calidad_id_control_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.control_calidad_id_control_seq', 1, false);


--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 236
-- Name: detalle_nota_salida_id_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.detalle_nota_salida_id_detalle_seq', 9, true);


--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 270
-- Name: detalle_pedido_id_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.detalle_pedido_id_detalle_seq', 65, true);


--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 238
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 240
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 10, true);


--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 242
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 22, true);


--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 272
-- Name: facturas_id_factura_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.facturas_id_factura_seq', 6, true);


--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 245
-- Name: inventario_id_inventario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventario_id_inventario_seq', 15, true);


--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 247
-- Name: lotes_id_lote_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lotes_id_lote_seq', 16, true);


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 249
-- Name: materias_primas_id_materia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.materias_primas_id_materia_seq', 52, true);


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 274
-- Name: modelos_prediccion_id_modelo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modelos_prediccion_id_modelo_seq', 2, true);


--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 251
-- Name: nota_salida_id_salida_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.nota_salida_id_salida_seq', 4, true);


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 253
-- Name: orden_produccion_id_orden_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orden_produccion_id_orden_seq', 4, true);


--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 268
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_id_pedido_seq', 33, true);


--
-- TOC entry 5227 (class 0 OID 0)
-- Dependencies: 255
-- Name: permisos_id_permiso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permisos_id_permiso_seq', 16, true);


--
-- TOC entry 5228 (class 0 OID 0)
-- Dependencies: 257
-- Name: personal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_id_seq', 5, true);


--
-- TOC entry 5229 (class 0 OID 0)
-- Dependencies: 266
-- Name: precios_id_precio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.precios_id_precio_seq', 40, true);


--
-- TOC entry 5230 (class 0 OID 0)
-- Dependencies: 276
-- Name: predicciones_pedidos_id_prediccion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.predicciones_pedidos_id_prediccion_seq', 9, true);


--
-- TOC entry 5231 (class 0 OID 0)
-- Dependencies: 259
-- Name: trazabilidad_id_trazabilidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trazabilidad_id_trazabilidad_seq', 9, true);


--
-- TOC entry 5232 (class 0 OID 0)
-- Dependencies: 261
-- Name: turnos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.turnos_id_seq', 8, true);


--
-- TOC entry 5233 (class 0 OID 0)
-- Dependencies: 263
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 21, true);


--
-- TOC entry 4843 (class 2606 OID 35802)
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- TOC entry 4848 (class 2606 OID 35804)
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- TOC entry 4851 (class 2606 OID 35806)
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4845 (class 2606 OID 35808)
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 4854 (class 2606 OID 35810)
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- TOC entry 4856 (class 2606 OID 35812)
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 4864 (class 2606 OID 35814)
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 4867 (class 2606 OID 35816)
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- TOC entry 4858 (class 2606 OID 35818)
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- TOC entry 4870 (class 2606 OID 35820)
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4873 (class 2606 OID 35822)
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- TOC entry 4861 (class 2606 OID 35824)
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- TOC entry 4875 (class 2606 OID 35826)
-- Name: bitacora bitacora_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bitacora
    ADD CONSTRAINT bitacora_pkey PRIMARY KEY (id_bitacora);


--
-- TOC entry 4925 (class 2606 OID 36169)
-- Name: clientes clientes_nombre_completo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_nombre_completo_key UNIQUE (nombre_completo);


--
-- TOC entry 4927 (class 2606 OID 36167)
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- TOC entry 4877 (class 2606 OID 35828)
-- Name: control_asistencia control_asistencia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_asistencia
    ADD CONSTRAINT control_asistencia_pkey PRIMARY KEY (id_control);


--
-- TOC entry 4879 (class 2606 OID 35830)
-- Name: control_calidad control_calidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_calidad
    ADD CONSTRAINT control_calidad_pkey PRIMARY KEY (id_control);


--
-- TOC entry 4881 (class 2606 OID 35832)
-- Name: detalle_nota_salida detalle_nota_salida_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_nota_salida
    ADD CONSTRAINT detalle_nota_salida_pkey PRIMARY KEY (id_detalle);


--
-- TOC entry 4935 (class 2606 OID 36529)
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (id_detalle);


--
-- TOC entry 4884 (class 2606 OID 35834)
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4887 (class 2606 OID 35836)
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- TOC entry 4889 (class 2606 OID 35838)
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4891 (class 2606 OID 35840)
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 35842)
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- TOC entry 4937 (class 2606 OID 36547)
-- Name: facturas facturas_cod_factura_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_cod_factura_key UNIQUE (cod_factura);


--
-- TOC entry 4939 (class 2606 OID 36545)
-- Name: facturas facturas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_pkey PRIMARY KEY (id_factura);


--
-- TOC entry 4897 (class 2606 OID 35844)
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id_inventario);


--
-- TOC entry 4899 (class 2606 OID 35846)
-- Name: lotes lotes_codigo_lote_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lotes
    ADD CONSTRAINT lotes_codigo_lote_key UNIQUE (codigo_lote);


--
-- TOC entry 4901 (class 2606 OID 35848)
-- Name: lotes lotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lotes
    ADD CONSTRAINT lotes_pkey PRIMARY KEY (id_lote);


--
-- TOC entry 4903 (class 2606 OID 35850)
-- Name: materias_primas materias_primas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materias_primas
    ADD CONSTRAINT materias_primas_pkey PRIMARY KEY (id_materia);


--
-- TOC entry 4941 (class 2606 OID 36563)
-- Name: modelos_prediccion modelos_prediccion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelos_prediccion
    ADD CONSTRAINT modelos_prediccion_pkey PRIMARY KEY (id_modelo);


--
-- TOC entry 4905 (class 2606 OID 35852)
-- Name: nota_salida nota_salida_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_salida
    ADD CONSTRAINT nota_salida_pkey PRIMARY KEY (id_salida);


--
-- TOC entry 4907 (class 2606 OID 35854)
-- Name: orden_produccion orden_produccion_cod_orden_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_cod_orden_key UNIQUE (cod_orden);


--
-- TOC entry 4909 (class 2606 OID 35856)
-- Name: orden_produccion orden_produccion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_pkey PRIMARY KEY (id_orden);


--
-- TOC entry 4931 (class 2606 OID 36512)
-- Name: pedidos pedidos_cod_pedido_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cod_pedido_key UNIQUE (cod_pedido);


--
-- TOC entry 4933 (class 2606 OID 36510)
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id_pedido);


--
-- TOC entry 4911 (class 2606 OID 35858)
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- TOC entry 4913 (class 2606 OID 35860)
-- Name: personal personal_nombre_completo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_nombre_completo_key UNIQUE (nombre_completo);


--
-- TOC entry 4915 (class 2606 OID 35862)
-- Name: personal personal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_pkey PRIMARY KEY (id);


--
-- TOC entry 4929 (class 2606 OID 36204)
-- Name: precios precios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precios
    ADD CONSTRAINT precios_pkey PRIMARY KEY (id_precio);


--
-- TOC entry 4943 (class 2606 OID 36571)
-- Name: predicciones_pedidos predicciones_pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predicciones_pedidos
    ADD CONSTRAINT predicciones_pedidos_pkey PRIMARY KEY (id_prediccion);


--
-- TOC entry 4917 (class 2606 OID 35864)
-- Name: trazabilidad trazabilidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trazabilidad
    ADD CONSTRAINT trazabilidad_pkey PRIMARY KEY (id_trazabilidad);


--
-- TOC entry 4919 (class 2606 OID 35866)
-- Name: turnos turnos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_pkey PRIMARY KEY (id);


--
-- TOC entry 4921 (class 2606 OID 35868)
-- Name: usuarios usuarios_name_user_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_name_user_key UNIQUE (name_user);


--
-- TOC entry 4923 (class 2606 OID 35870)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 4841 (class 1259 OID 35871)
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- TOC entry 4846 (class 1259 OID 35872)
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- TOC entry 4849 (class 1259 OID 35873)
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- TOC entry 4852 (class 1259 OID 35874)
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- TOC entry 4862 (class 1259 OID 35875)
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- TOC entry 4865 (class 1259 OID 35876)
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- TOC entry 4868 (class 1259 OID 35877)
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- TOC entry 4871 (class 1259 OID 35878)
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- TOC entry 4859 (class 1259 OID 35879)
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- TOC entry 4882 (class 1259 OID 35880)
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- TOC entry 4885 (class 1259 OID 35881)
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- TOC entry 4892 (class 1259 OID 35882)
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- TOC entry 4895 (class 1259 OID 35883)
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- TOC entry 4944 (class 2606 OID 35884)
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4945 (class 2606 OID 35889)
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4946 (class 2606 OID 35894)
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4947 (class 2606 OID 35899)
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4948 (class 2606 OID 35904)
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4949 (class 2606 OID 35909)
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4950 (class 2606 OID 35914)
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4967 (class 2606 OID 36170)
-- Name: clientes clientes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4951 (class 2606 OID 35919)
-- Name: control_asistencia control_asistencia_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_asistencia
    ADD CONSTRAINT control_asistencia_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id) ON DELETE RESTRICT;


--
-- TOC entry 4952 (class 2606 OID 35924)
-- Name: control_asistencia control_asistencia_id_turno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_asistencia
    ADD CONSTRAINT control_asistencia_id_turno_fkey FOREIGN KEY (id_turno) REFERENCES public.turnos(id) ON DELETE RESTRICT;


--
-- TOC entry 4953 (class 2606 OID 35929)
-- Name: control_calidad control_calidad_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_calidad
    ADD CONSTRAINT control_calidad_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4954 (class 2606 OID 35934)
-- Name: control_calidad control_calidad_id_trazabilidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.control_calidad
    ADD CONSTRAINT control_calidad_id_trazabilidad_fkey FOREIGN KEY (id_trazabilidad) REFERENCES public.trazabilidad(id_trazabilidad) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4955 (class 2606 OID 35939)
-- Name: detalle_nota_salida detalle_nota_salida_id_lote_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_nota_salida
    ADD CONSTRAINT detalle_nota_salida_id_lote_fkey FOREIGN KEY (id_lote) REFERENCES public.lotes(id_lote) ON DELETE CASCADE;


--
-- TOC entry 4956 (class 2606 OID 35944)
-- Name: detalle_nota_salida detalle_nota_salida_id_salida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_nota_salida
    ADD CONSTRAINT detalle_nota_salida_id_salida_fkey FOREIGN KEY (id_salida) REFERENCES public.nota_salida(id_salida) ON DELETE CASCADE;


--
-- TOC entry 4969 (class 2606 OID 36530)
-- Name: detalle_pedido detalle_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- TOC entry 4957 (class 2606 OID 35949)
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4958 (class 2606 OID 35954)
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 4970 (class 2606 OID 36548)
-- Name: facturas facturas_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- TOC entry 4959 (class 2606 OID 35959)
-- Name: inventario inventario_id_lote_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_id_lote_fkey FOREIGN KEY (id_lote) REFERENCES public.lotes(id_lote) ON DELETE CASCADE;


--
-- TOC entry 4960 (class 2606 OID 35964)
-- Name: lotes lotes_id_materia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lotes
    ADD CONSTRAINT lotes_id_materia_fkey FOREIGN KEY (id_materia) REFERENCES public.materias_primas(id_materia) ON DELETE CASCADE;


--
-- TOC entry 4961 (class 2606 OID 35969)
-- Name: nota_salida nota_salida_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_salida
    ADD CONSTRAINT nota_salida_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id) ON DELETE CASCADE;


--
-- TOC entry 4962 (class 2606 OID 35974)
-- Name: orden_produccion orden_produccion_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4968 (class 2606 OID 36513)
-- Name: pedidos pedidos_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4963 (class 2606 OID 35979)
-- Name: permisos permisos_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4964 (class 2606 OID 35984)
-- Name: personal personal_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id);


--
-- TOC entry 4971 (class 2606 OID 36572)
-- Name: predicciones_pedidos predicciones_pedidos_id_modelo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predicciones_pedidos
    ADD CONSTRAINT predicciones_pedidos_id_modelo_fkey FOREIGN KEY (id_modelo) REFERENCES public.modelos_prediccion(id_modelo);


--
-- TOC entry 4965 (class 2606 OID 35989)
-- Name: trazabilidad trazabilidad_id_orden_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trazabilidad
    ADD CONSTRAINT trazabilidad_id_orden_fkey FOREIGN KEY (id_orden) REFERENCES public.orden_produccion(id_orden) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4966 (class 2606 OID 35994)
-- Name: trazabilidad trazabilidad_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trazabilidad
    ADD CONSTRAINT trazabilidad_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2025-11-05 18:46:33

--
-- PostgreSQL database dump complete
--

