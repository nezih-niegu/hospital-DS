--------------------------------------------------------------------------------
--  Escalas(4at/cam)
--------------------------------------------------------------------------------
-- 4AT
-- 1 - estado de consciencia
-- 2 - AMT4 (edad, fecha de nacimiento, lugar, año)
-- 3 - atencion
-- 4 - cambio agudo o curso fluctuante
--CAM

SELECT * FROM [dbo].[tt04_tamizaje] WHERE coalesce([4ATorCAMICU], [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
) IS NULL -- No queremos los registros que tienen todas las columnas que nos interesan
-- como nulas, entonces usamos el opuesto de este comando

--------------------------- 4at/cam de tamizaje
select
ID_paciente, ID_fecha, fecha, hora, 
[4ATorCAMICU], [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
from [dbo].[tt04_tamizaje]
WHERE coalesce([4ATorCAMICU], [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
) IS not NULL


select ID_paciente, ID_fecha, fecha, hora,
		case
			when [4at_score] > 3
				then 'Delirium likely'
			when  [4at_score] > 0 and  [4at_score] < 4
				then 'Possible cognitive impairment'
			when [4at_score] = 0
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU negativo'
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU positivo'
				then 'Delirium likely'
		end as delirium, delirium_test
from
(
	select
			ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
				then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
			end as [4at_score],
			case
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
				then 'CAM-ICU negativo'
			end as cam_result,
			case
				when [4at_conciencia] is not null
					then '4AT'
				when [cam_b_inicio_fluctuacion] is not null
					then 'CAM-ICU'
			end as delirium_test
	from [dbo].[tt04_tamizaje]
	WHERE coalesce
	(
		[4at_conciencia], [4at_amt4],
		[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
		[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
	) IS not NULL
) t


--------------------------- 4at/cam de 4at_camicu
select
ID_paciente, ID_fecha, fecha, hora, 
[4ATorCAMICU], [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
from [dbo].[tt02_4at_camicu]
WHERE coalesce([4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
) IS not NULL


select ID_paciente, ID_fecha, fecha, hora,
		case
			when [4at_score] > 3
				then 'Delirium likely'
			when  [4at_score] > 0 and  [4at_score] < 4
				then 'Possible cognitive impairment'
			when [4at_score] = 0
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU negativo'
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU positivo'
				then 'Delirium likely'
		end as delirium, delirium_test
from
(
	select
			ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
				then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
			end as [4at_score],
			case
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
				then 'CAM-ICU negativo'
			end as cam_result,
			case
				when [4at_conciencia] is not null
					then '4AT'
				when [cam_b_inicio_fluctuacion] is not null
					then 'CAM-ICU'
			end as delirium_test
	from [dbo].[tt02_4at_camicu]
	WHERE coalesce
	(
		[4at_conciencia], [4at_amt4],
		[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
		[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
	) IS not NULL
) t

--------------------------- 4at de prev_delirium

select
ID_paciente, ID_fecha, fecha, hora, 
[4ATorCAMICU], [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_rass], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
from [dbo].[tt01_prev_delirium]
WHERE coalesce( [4at_conciencia], [4at_amt4],
[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
) IS not NULL

select ID_paciente, ID_fecha, fecha, hora,
		case
			when [4at_score] > 3
				then 'Delirium likely'
			when  [4at_score] > 0 and  [4at_score] < 4
				then 'Possible cognitive impairment'
			when [4at_score] = 0
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU negativo'
				then 'Delirium unlikely'
			when cam_result like 'CAM-ICU positivo'
				then 'Delirium likely'
		end as delirium, delirium_test
from
(
	select
			ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
				then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
			end as [4at_score],
			case
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
				then 'CAM-ICU negativo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
				then 'CAM-ICU positivo'
				when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
				then 'CAM-ICU negativo'
			end as cam_result,
			case
				when [4at_conciencia] is not null
					then '4AT'
				when [cam_b_inicio_fluctuacion] is not null
					then 'CAM-ICU'
			end as delirium_test
	from [dbo].[tt01_prev_delirium]
	WHERE coalesce
	(
		[4at_conciencia], [4at_amt4],
		[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
		[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
	) IS not NULL
) t

--------------------------------------------------------------------------------
-- TODO JUNTO
--------------------------------------------------------------------------------
drop table tt_delirium
select * 
into tt_delirium
from
(
	select ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_score] > 3
					then 'Delirium likely'
				when  [4at_score] > 0 and  [4at_score] < 4
					then 'Possible cognitive impairment'
				when [4at_score] = 0
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU negativo'
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU positivo'
					then 'Delirium likely'
			end as delirium, delirium_test
	from
	(
		select
				ID_paciente, ID_fecha, fecha, hora,
				case
					when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
					then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
				end as [4at_score],
				case
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
					then 'CAM-ICU negativo'
				end as cam_result,
				case
					when [4at_conciencia] is not null
						then '4AT'
					when [cam_b_inicio_fluctuacion] is not null
						then 'CAM-ICU'
				end as delirium_test
		from [dbo].[tt04_tamizaje]
		WHERE coalesce
		(
			[4at_conciencia], [4at_amt4],
			[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
			[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
		) IS not NULL
	) t
	union all
	select ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_score] > 3
					then 'Delirium likely'
				when  [4at_score] > 0 and  [4at_score] < 4
					then 'Possible cognitive impairment'
				when [4at_score] = 0
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU negativo'
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU positivo'
					then 'Delirium likely'
			end as delirium, delirium_test
	from
	(
		select
				ID_paciente, ID_fecha, fecha, hora,
				case
					when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
					then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
				end as [4at_score],
				case
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
					then 'CAM-ICU negativo'
				end as cam_result,
				case
					when [4at_conciencia] is not null
						then '4AT'
					when [cam_b_inicio_fluctuacion] is not null
						then 'CAM-ICU'
				end as delirium_test
		from [dbo].[tt02_4at_camicu]
		WHERE coalesce
		(
			[4at_conciencia], [4at_amt4],
			[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
			[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
		) IS not NULL
	) t
	union all
	select ID_paciente, ID_fecha, fecha, hora,
			case
				when [4at_score] > 3
					then 'Delirium likely'
				when  [4at_score] > 0 and  [4at_score] < 4
					then 'Possible cognitive impairment'
				when [4at_score] = 0
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU negativo'
					then 'Delirium unlikely'
				when cam_result like 'CAM-ICU positivo'
					then 'Delirium likely'
			end as delirium, delirium_test
	from
	(
		select
				ID_paciente, ID_fecha, fecha, hora,
				case
					when [4at_conciencia] is not null and [4at_amt4] is not null and [4at_atencion] is not null and [4at_cambio_fluctuacion] is not null
					then (cast(left([4at_conciencia],1) as int))+(cast(left([4at_amt4],1) as int))+(cast(left([4at_atencion],1) as int))+(cast(left([4at_cambio_fluctuacion],1) as int))
				end as [4at_score],
				case
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%ausente%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] not like '%3%'
					then 'CAM-ICU negativo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] not like '%0%'
					then 'CAM-ICU positivo'
					when [cam_rass] is not null and ([cam_rass] not like '%-5%' and [cam_rass] not like '%-4%') and [cam_b_inicio_fluctuacion] is not null and [cam_b_inicio_fluctuacion] like '%presente%' and [cam_b_inatencion] is not null and [cam_b_inatencion] like '%3%' and [cam_b_rass_actual] like '%0%' and [cam_b_pensamientodesorg] is not null and [cam_b_pensamientodesorg] like '%0%'
					then 'CAM-ICU negativo'
				end as cam_result,
				case
					when [4at_conciencia] is not null
						then '4AT'
					when [cam_b_inicio_fluctuacion] is not null
						then 'CAM-ICU'
				end as delirium_test
		from [dbo].[tt01_prev_delirium]
		WHERE coalesce
		(
			[4at_conciencia], [4at_amt4],
			[4at_atencion], [4at_cambio_fluctuacion], [cam_b_inicio_fluctuacion], 
			[cam_b_inatencion], [cam_b_rass_actual], [cam_b_pensamientodesorg]
		) IS not NULL
	) t
) t

--------------------------------------------------------------------------------
--  Escalas(dolor, sleep, HADS, EPPAH) y rehab
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  Escalas(sleep, HADS, EPPAH) y rehab
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  Escalas(HADS, EPPAH) y rehab
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  Escalas(EPPAH)y rehab
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  Rehab
--------------------------------------------------------------------------------





