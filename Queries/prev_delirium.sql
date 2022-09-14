--------------------------------------------------------------------------------
-- Prev_delirium
--------------------------------------------------------------------------------

select * from [dbo].[prev_delirium]
where ID like '%[a-z.,-%&@#$*]%'

select * from [dbo].[prev_delirium]
where ID > 6000

drop table prev_delirium
select
try_cast(b.correctID as int) as ID_paciente, c.ID_fecha, convert(date,a.[Marca_temporal],23) as fecha, convert(time,a.[Marca_temporal],24) as hora
, a.[dolor_escala], a.[dolor_numerico], a.[dolor_ubicacion], a.[expresion_facial]
, a.[movim_miembros_sup], a.[ventilacion_mecanica], a.[rc_sleep_anoche]
, a.[rc_sleep_when], a.[rc_sleep_amount], a.[rc_sleep_backtosleep]
, a.[rc_sleep_quality], a.[4at_conciencia], a.[4at_amt4], a.[4at_atencion]
, a.[4at_cambio_fluctuacion], a.[orientacion], a.[deambulacion_temp]
, a.[ritmo_circadiano], a.[alimentacion_hidratacion], a.[comunicacion]
, a.[ejercicios_cognitivos], a.[def_sensorial], a.[4ATorCAMICU], a.[cam_rass]
, a.[cam_b_inicio_fluctuacion], a.[cam_b_inatencion], a.[cam_b_rass_actual]
, a.[cam_b_pensamientodesorg]
into tt01_prev_delirium
from
	[dbo].[prev_delirium] as a,
	[dbo].[CorrectIDs] as b,
	[dbo].[tt01_fechas] as c
where a.ID = b.ID and b.ID is not null and convert(date,a.[Marca_temporal],23) = c.fecha