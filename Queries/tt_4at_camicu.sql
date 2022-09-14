------------------------------------------------------------------------------------
----------------- 4AT or CAM-ICU ---------------------------------------------------
------------------------------------------------------------------------------------

select * from [dbo].[4at_camicu]
where ID like '%[a-z.,-%&@#$*]%'

drop table tt_4at_camicu
select * 
--into tt_4at_camicu
from [dbo].[4at_camicu]
where ID not like '%[a-z.,-%&@#$*]%'

-- corregir IDs y agregar ID_fecha

drop table tt01_4at_camicu
select
cast(b.correctID as int) as ID_paciente
, c.ID_fecha, a.Marca_temporal , a.[hospital], a.[cuarto_sanjose], a.[area_sanjose]
, a.[cuarto_zambrano], a.[area_zambrano], a.[terapia_oxigeno], a.[nivel_conciencia]
, a.[4ATorCAMICU], a.[4at_conciencia], a.[4at_amt4], a.[4at_atencion]
, a.[4at_cambio_fluctuacion], a.[cam_rass], a.[cam_b_inicio_fluctuacion]
, a.[cam_b_inatencion], a.[cam_b_rass_actual], a.[cam_b_pensamientodesorg]
, a.[dolor_escala], a.[dolor_numerico], a.[dolor_ubicacion], a.[expresion_facial]
, a.[movim_miembros_sup], a.[ventilacion_mecanica], a.[sleep_quality_filtro]
, a.[sleep_score_filtro], a.[rc_sleep_anoche], a.[rc_sleep_when]
, a.[rc_sleep_amount], a.[rc_sleep_backtosleep], a.[rc_sleep_quality]
, a.[rc_sleep_7minus], a.[rc_6_preocupacion_nervios], a.[rc_6_ruidos_maquinaria]
, a.[rc_6_ruidos_personal], a.[rc_6_intervenciones], a.[rc_6_dolor]
, a.[rc_6_disconfort], a.[rc_6_luz], a.[rc_6_presencias], a.[rc_6_otros]
, a.[rc_6_otros2], a.[HADS_filtro], a.[hads_a1], a.[hads_d1], a.[hads_a2]
, a.[hads_d2], a.[hads_a3], a.[hads_d3], a.[hads_a4], a.[hads_d4], a.[hads_a5]
, a.[hads_d5], a.[hads_a6], a.[hads_d6], a.[hads_a7], a.[hads_d7]
, a.[news2_traqueostomia], a.[EPPAH_aplicado], a.[eppah_enf], a.[eppah_dolor]
, a.[eppah_familiaridad], a.[eppah_anestesia], a.[eppah_separacion]
, a.[eppah_estres], a.[eppah_gastos], a.[eppah_rutina], a.[eppah_control]
, a.[eppah_incertidumbre], a.[eppah_muerte], a.[eppah_otro], a.[eppah_otro2]
into tt01_4at_camicu
from
tt_4at_camicu as a,
[dbo].[CorrectIDs] as b,
[dbo].[tt01_fechas] as c
where a.ID = b.ID and b.ID is not null and convert(date,a.[Marca_temporal],23) = c.fecha

select * from tt01_4at_camicu 
order by ID_paciente
-- son 11303 registros

select * from tt01_4at_camicu where cuarto_sanjose is not null or area_sanjose is not null or hospital like 'San José'
select * from tt01_4at_camicu where cuarto_zambrano is not null or area_zambrano is not null or hospital like 'Zambrano'
select * from tt01_4at_camicu where cuarto_zambrano is null and area_zambrano is null and cuarto_sanjose is null or area_sanjose is null
-- son 11302 registros, por lo que uno de ellos no especifica hospital
select * from tt04_pacientes where ID_paciente like '1042'
-- Al buscar al paciente, encontramos que entro al cuarto 132, por lo que el hospital es 
--San Jose (los cuartos del zambrano se numeran diferente)

select distinct([cuarto_sanjose]) from tt01_4at_camicu
select distinct([area_sanjose]) from tt01_4at_camicu 
select distinct([cuarto_zambrano]) from tt01_4at_camicu
select distinct([area_zambrano]) from tt01_4at_camicu 
select * from tt01_4at_camicu where cuarto_sanjose is null or area_sanjose is  null

drop table tt02_4at_camicu
select 
		[ID_paciente], [ID_fecha], convert(date,[Marca_temporal],23) as fecha, 
		convert(time,marca_temporal,24) as hora,
		case 
			when area_sanjose like 'terapia intensiva%'
			then 'UTIA'
			when area_sanjose like 'terapia intermedia%'
			then 'UTIM'
			when area_sanjose like 'piso%'
			then 'Piso'
			when area_sanjose like 'post%'
			then 'Post-terapia'
			when area_sanjose like 'Emergencias'
			then 'Emergencias'
			when cuarto_zambrano like '3%' or cuarto_zambrano like '4%'
			then 'Piso'
			when cuarto_zambrano like '2%'
			then 'UTIA'
		end as area,
		case
			when cuarto_sanjose is not null or area_sanjose is not null or hospital like 'San %'
				then 'San José'
			when cuarto_zambrano is not null or area_zambrano is not null or hospital like 'Zam%'
				then 'Zambrano'
			when ID_paciente like '1042'
				then 'San José'
			else null
		end as hospital,
		[cuarto_sanjose], [area_sanjose], 
		[cuarto_zambrano], [area_zambrano], [terapia_oxigeno], [nivel_conciencia]
		, [4ATorCAMICU], [4at_conciencia], [4at_amt4], [4at_atencion]
		, [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion]
		, [cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
		, [dolor_escala], [dolor_numerico], [dolor_ubicacion], [expresion_facial]
		, [movim_miembros_sup], [ventilacion_mecanica], [sleep_quality_filtro]
		, [sleep_score_filtro], [rc_sleep_anoche], [rc_sleep_when]
		, [rc_sleep_amount], [rc_sleep_backtosleep], [rc_sleep_quality]
		, [rc_sleep_7minus], [rc_6_preocupacion_nervios], [rc_6_ruidos_maquinaria]
		, [rc_6_ruidos_personal], [rc_6_intervenciones], [rc_6_dolor]
		, [rc_6_disconfort], [rc_6_luz], [rc_6_presencias], [rc_6_otros]
		, [rc_6_otros2], [HADS_filtro], [hads_a1], [hads_d1], [hads_a2]
		, [hads_d2], [hads_a3], [hads_d3], [hads_a4], [hads_d4], [hads_a5]
		, [hads_d5], [hads_a6], [hads_d6], [hads_a7], [hads_d7]
		, [news2_traqueostomia], [EPPAH_aplicado], [eppah_enf], [eppah_dolor]
		, [eppah_familiaridad], [eppah_anestesia], [eppah_separacion]
		, [eppah_estres], [eppah_gastos], [eppah_rutina], [eppah_control]
		, [eppah_incertidumbre], [eppah_muerte], [eppah_otro], [eppah_otro2]
into tt02_4at_camicu
from tt01_4at_camicu
