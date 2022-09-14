------------------------------------------------------------------------------------
--Tamizaje
------------------------------------------------------------------------------------
--------------------------------- corregir IDs -------------------------------------
-- Primer paso, as usual, es corregir el ID de la tabla, quitamos los registros no 
-- validos (que tengan ID no numerico) y corregimos a correctID de 
-- nuestra tabla correctIDs

select * from tamizaje
where ID like '%[^0-9]%'

select * from tamizaje 
where len(ID) > 5

-- De tener 1103 registros, pasamos a tener 1097

drop table tt01_tamizaje
select a.correctID as ID_paciente, b.*
into tt01_tamizaje
from [dbo].[CorrectIDs] as a, 
(
	select * from tamizaje
	where ID like '%[0-9]%' and len(ID) < 6
) as b
where b.ID = a.ID

------------------------------------------------------------------------------------
-- Lo que tiene esta tabla de particular, es que la marca temporal no siempre es la 
-- misma que la fecha de aplicacion del tamizaje. Por lo tanto, tenemos que corregir
--la marca temporal a que sea la misma que la fecha del tamizaje.
-- De paso quitamos las columnas de notas porque no podemos estandarizar
-- ni analizarlas "in bulk".

drop table tt02_tamizaje
select 
		ID_paciente,
		case
			when diferencia_fecha > -14 and diferencia_fecha <15
			then dateadd(day,diferencia_fecha,fecha_marca)
			else fecha_marca
		end as fecha,
		case
			when hora_tamizaje is not null
			then hora_tamizaje
			else hora_marca
		end as hora, [hospital], [cuarto_sanjose], [area_sanjose], [cuarto_zambrano], 
		[area_zambrano], [dolor_escala], [dolor_numerico], [dolor_ubicacion], 
		[expresion_facial], [movim_miembros_sup], [ventilacion_mecanica], 
		[slept_at_hospital_anoche], [sleep_quality_filtro], [rc_sleep_anoche], 
		[rc_sleep_when], [rc_sleep_amount], [rc_sleep_backtosleep], 
		[rc_sleep_quality], [rc_sleep_7minus], [rc_6_preocupacion_nervios], 
		[rc_6_ruidos_maquinaria], [rc_6_ruidos_personal], [rc_6_intervenciones], 
		[rc_6_dolor], [rc_6_disconfort], [rc_6_luz], [rc_6_presencias], 
		[k10_cansancio], [k10_nerviosismo], [k10_ansiedad], [k10_desesperacion], 
		[k10_inquietud], [k10_impaciencia_restlessness], [k10_depresion], 
		[k10_esfuerzo_act], [k10_tristeza], [k10_inutileza], [filtro_delirium_ICU], 
		[filtro_delirium_65plus_other], [4ATorCAMICU], [4at_conciencia], [4at_amt4], 
		[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], 
		[cam_b_inicio_fluctuacion], [cam_b_inatencion], [cam_b_rass_actual], 
		[cam_b_pensamientodesorg], [news2_traqueostomia], [news2_terapiaoxigeno], 
		[news2_conciencia], [aplicacion_k10]
into tt02_tamizaje
from
		(
		select datediff(day,fecha_tamizaje,fecha_marca) as diferencia_fecha, *
		from
			(
			select convert(date, marca_temporal, 23) as fecha_marca, convert(time, marca_temporal, 24) as hora_marca,
					case
						when [fecha_if_diff] like '00%'
						then '20'+ right([fecha_if_diff],8)
						when [fecha_if_diff] like '202[2-9]%'
						then '2021'+right([fecha_if_diff],6)
						when [fecha_if_diff] like '2001%'
						then '2021'+right([fecha_if_diff],6)
						when [fecha_if_diff] like '19%'
						then null
						when [fecha_if_diff] like '02%'
						then null
						else [fecha_if_diff]
					end as fecha_tamizaje,
						case
						when [hora_tamizaje24h] like '[0-9]:%' and [hora_tamizaje24h] like '%a%'
						then '0'+left([hora_tamizaje24h],7)
						when [hora_tamizaje24h] like '[0-9][0-9]:%' and [hora_tamizaje24h] like '%a%'
						then left([hora_tamizaje24h],8)
						when [hora_tamizaje24h] like '[0-9]:%' and [hora_tamizaje24h] like '%p%'
						then cast((cast((left([hora_tamizaje24h],1)) as int))+12 as varchar) +substring([hora_tamizaje24h],2,6)
						when [hora_tamizaje24h] like '[0-9][0-9]:%' and [hora_tamizaje24h] like '%p%' and [hora_tamizaje24h] not like '12%'
						then (cast((cast((left([hora_tamizaje24h],2)) as int))+12 as varchar))+substring([hora_tamizaje24h],3,6)
						when [hora_tamizaje24h] like '12:%' and [hora_tamizaje24h] like '%p%'
						then '12'+substring([hora_tamizaje24h],3,6)
						else [hora_tamizaje24h]
					end as hora_tamizaje, *
			from tt01_tamizaje
			) t
		) t
------------------------------------------------------------------------------------
-- Ahora tenemos una tt02_tamizaje
-- Tenemos que cambiarle la fecha por un ID_fecha
drop table tt03_tamizaje
select a.ID_fecha, b.*
into tt03_tamizaje
from [dbo].[tt01_fechas] as a, [dbo].[tt02_tamizaje] as b
where a.fecha = b.fecha

select * from tt03_tamizaje
-- Son 1097 registros.
------------------------------------------------------------------------------------
-- Hospital
select distinct(hospital) from tt03_tamizaje
-- se queda igual
------------------------------------------------------------------------------------
-- Areas y cuartos

select distinct(cuarto_sanjose) from tt03_tamizaje
select distinct(area_sanjose) from tt03_tamizaje
select distinct(cuarto_zambrano) from tt03_tamizaje
select distinct(area_zambrano) from tt03_tamizaje

drop table tt04_tamizaje
select ID_fecha, ID_paciente, fecha, hora,
	case 
		when hospital like 'San%' and cuarto_sanjose like '1%'
		then 'UTIA'
		when hospital like 'San%' and (cuarto_sanjose like '3%' or cuarto_sanjose like '41%')
		then 'UTIM'
		when hospital like 'San%' and (cuarto_sanjose like '43%' or cuarto_sanjose like '5%' or cuarto_sanjose like '6%')
		then 'Piso'
		when hospital like 'San%' and (cuarto_sanjose like '7%' or cuarto_sanjose like '8%')
		then 'Post-terapia'
		when hospital like 'San%' and area_sanjose like 'Emergencias'
		then 'Emergencias'
		when hospital like 'Zamb%' and (cuarto_zambrano like '3%' or cuarto_zambrano like '4%')
		then 'Piso'
		when hospital like 'Zamb%' and cuarto_zambrano like '2%'
		then 'UTIA'
	end as area,
	hospital, cuarto_sanjose,
	case 
		when hospital like 'San%' and cuarto_sanjose like '1%'
		then 'Terapia intensiva (piso 1)'
		when hospital like 'San%' and (cuarto_sanjose like '3%' or cuarto_sanjose like '41%')
		then 'Terapia intermedia (3.1, 4.1)'
		when hospital like 'San%' and (cuarto_sanjose like '43%' or cuarto_sanjose like '5%' or cuarto_sanjose like '6%')
		then 'Piso (4.3, 5 y 6)'
		when hospital like 'San%' and (cuarto_sanjose like '7%' or cuarto_sanjose like '8%')
		then 'Post-terapia (7,8)'
		when hospital like 'San%' and area_sanjose like 'Emergencias'
		then 'Emergencias'
	end as area_sanjose, [cuarto_zambrano], 
		[area_zambrano], [dolor_escala], [dolor_numerico], [dolor_ubicacion], 
		[expresion_facial], [movim_miembros_sup], [ventilacion_mecanica], 
		[slept_at_hospital_anoche], [sleep_quality_filtro], [rc_sleep_anoche], 
		[rc_sleep_when], [rc_sleep_amount], [rc_sleep_backtosleep], 
		[rc_sleep_quality], [rc_sleep_7minus], [rc_6_preocupacion_nervios], 
		[rc_6_ruidos_maquinaria], [rc_6_ruidos_personal], [rc_6_intervenciones], 
		[rc_6_dolor], [rc_6_disconfort], [rc_6_luz], [rc_6_presencias], 
		[k10_cansancio], [k10_nerviosismo], [k10_ansiedad], [k10_desesperacion], 
		[k10_inquietud], [k10_impaciencia_restlessness], [k10_depresion], 
		[k10_esfuerzo_act], [k10_tristeza], [k10_inutileza], [filtro_delirium_ICU], 
		[filtro_delirium_65plus_other], [4ATorCAMICU], [4at_conciencia], [4at_amt4], 
		[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], 
		[cam_b_inicio_fluctuacion], [cam_b_inatencion], [cam_b_rass_actual], 
		[cam_b_pensamientodesorg], [news2_traqueostomia], [news2_terapiaoxigeno], 
		[news2_conciencia], [aplicacion_k10]
into tt04_tamizaje
from [dbo].[tt03_tamizaje]
------------------------------------------------------------------------------------
