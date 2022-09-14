------------------------------------------------------------------------------------
-- Altas_Def--
------------------------------------------------------------------------------------
select * from [dbo].[altas_def] -- son 4009 registros

-- Corregimos ID_paciente y agregamos ID_fecha

select * from [dbo].[altas_def]
where [ID] like '%[^0-9]%'

select try_cast(ID as int) from altas_def

drop table tt01_altas_def
select
		case
			when [ID] like '%[^0-9]%'
				then null
			when try_cast(ID as int) not like '%[^0-9]%' and try_cast(ID as int) is null
				then null
			else try_cast(ID as int)
		end as ID_paciente,
		case
			when [fecha_cambio] like '00%'
			then '20'+ right([fecha_cambio],8)
			when [fecha_cambio] like '202[2-9]%' and year(marca_temporal)<2022
			then '2021'+right(fecha_cambio,6)
			when [fecha_cambio] like '2921%' and year(marca_temporal)<2022
			then '2021'+right(fecha_cambio,6)
			when [fecha_cambio] like '2011%' and year(marca_temporal)<2022 and year(marca_temporal)>2020
			then '2021'+right(fecha_cambio,6)
			when [fecha_cambio] like '2011%' and year(marca_temporal)<2021 and year(marca_temporal)>2019
			then '2020'+right(fecha_cambio,6)
			when [fecha_cambio] like '19%'
			then convert(date,marca_temporal,23)
			when fecha_cambio like '02%'
			then convert(date,marca_temporal,23)
			else [fecha_cambio]
		end as fecha_cambio, 
		case
			when [hora_cambio] like '[0-9]:%' and [hora_cambio] like '%a%'
			then '0'+left([hora_cambio],7)
			when [hora_cambio] like '[0-9][0-9]:%' and [hora_cambio] like '%a%'
			then left([hora_cambio],8)
			when [hora_cambio] like '[0-9]:%' and [hora_cambio] like '%p%'
			then cast((cast((left([hora_cambio],1)) as int))+12 as varchar) +substring([hora_cambio],2,6)
			when [hora_cambio] like '[0-9][0-9]:%' and [hora_cambio] like '%p%' and [hora_cambio] not like '12%'
			then (cast((cast((left([hora_cambio],2)) as int))+12 as varchar))+substring([hora_cambio],3,6)
			when [hora_cambio] like '12:%' and [hora_cambio] like '%p%'
			then '12'+substring([hora_cambio],3,6)
			else [hora_cambio]
		end as [hora_cambio],
		case
			when [tipo_cambio] like '%prealta%'
			then 'Alta'
			when [tipo_cambio] like 'alta%'
			then 'Alta'
			when [tipo_cambio] like '%de%n'
			then 'Defuncion'
			else 'Sigue en el hospital'
		end as alta_def,
		tipo_cambio,
		[hospital_anterior]
into tt01_altas_def
from [dbo].[altas_def]

select * from tt01_altas_def order by fecha_cambio

drop table tt02_altas_def
select a.ID_paciente, b.ID_fecha, a.fecha_cambio, a.hora_cambio, a.alta_def, a.tipo_cambio, a.hospital_anterior
into tt02_altas_def
from [dbo].[tt01_altas_def] as a, [dbo].[tt01_fechas] as b
where a.fecha_cambio = b.Fecha and a.ID_paciente is not null

select * from tt02_altas_def order by ID_paciente, ID_fecha, fecha_cambio, hora_cambio
-- nos quedamos con 4008 registros porque uno no tenia ID_paciente
-- pero.. tenemos aun valores duplicados

---------------------------------------------------------------------------------
-- Parentesis hospital
---------------------------------------------------------------------------------
drop table tt_hospital
select distinct ID_paciente, hospital
into tt_hospital
from
(
select distinct cast(ID_paciente as int) as ID_paciente, hospital from tt02_4at_camicu where hospital is not null
union
select distinct cast(ID_paciente as int) as ID_paciente, hospital from tt04_tamizaje where hospital is not null
union
select distinct ID_paciente, hospital from tt04_pacientes where hospital is not null
union 
select distinct cast(ID_paciente as int) as ID_paciente, hospital_anterior as hospital from tt02_altas_def where hospital_anterior is not null
) t
where ID_paciente in 
(select ID_paciente from
tt04_pacientes)
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

drop table tt03_altas_def
select *
into tt03_altas_def
from
(
	select row_number() over (partition by ID_paciente, ID_fecha, hora_cambio order by hospital_anterior desc) as duptest, c.*
	from
		(
			select b.ID_paciente, b.ID_fecha, b.fecha_cambio, b.hora_cambio, b.alta_def, b.tipo_cambio, 
					case
						when b.hospital_anterior is null and a.ID_paciente = b.ID_paciente
						then a.hospital
						when b.hospital_anterior is not null 
						then b.hospital_anterior
					end as hospital_anterior
			from [dbo].[tt_hospital] as a, [dbo].[tt02_altas_def] as b
			where a.ID_paciente = b.ID_paciente
			union
			select * from tt02_altas_def
		) as c
) t
where duptest = 1

-- ya tenemos el hospital de los que lo tenian registrado, y ahora no tenemos duplicados
drop table tt04_altas_def
select 
		ID_paciente, ID_fecha, fecha_cambio, hora_cambio,
		case
			when [tipo_cambio] like '%alta%'
				then 'Alta'
			when [tipo_cambio] like '%de%n'
				then 'Defuncion'
			when [tipo_cambio] like '%utia%' and [tipo_cambio] not like '%utia a%' and [tipo_cambio] not like '%de UTIA%' and [tipo_cambio] not like '%covid%'
				then 'UTIA' -- UTIA es terapia intensiva
			when tipo_cambio like '%utia%' and (tipo_cambio like '%a utia%' or tipo_cambio like '%terapia intensiva%')
				then 'UTIA'
			when tipo_cambio like 'bloque 1' or tipo_cambio like '%esperando%intensiva%' or (tipo_cambio like '% 1%' and tipo_cambio not like '% 1%a') or tipo_cambio like '% a %intensiva%'
				then 'UTIA'
			when (tipo_cambio like '1%') and hospital_anterior like 'San%'
				then 'UTIA'
			when  tipo_cambio like '%00%' and hospital_anterior like 'San%'
				then 'Emergencias'
			when tipo_cambio like '%utim%' and tipo_cambio not like '%de%utim%' and tipo_cambio not like '%utim%a%p%so' and tipo_cambio not like '%utim%a%p%so'
				then 'UTIM'
			when tipo_cambio like '%utim%' and (tipo_cambio like '%a utim%' or tipo_cambio like '%utim cama%')
				then 'UTIM' -- UTIM es terapia intermedia
			when tipo_cambio like '% intermedia' or tipo_cambio like '%terapia intermedia ' or tipo_cambio like '%terapia 3%'
				then 'UTIM'
			when tipo_cambio like '%4.1%' and tipo_cambio not like '%de 4.1%'
				then 'UTIM'
			when (tipo_cambio like '3%' or tipo_cambio like '4%') and hospital_anterior like 'san%' and tipo_cambio not like '43%'
				then 'UTIM'
			when (tipo_cambio like '43%' or tipo_cambio like '6%' or tipo_cambio like '5%' or tipo_cambio like '%cambio 5%' or tipo_cambio like '%6[0-9][0-9]' or tipo_cambio like '%6[0-9][0-9] ' or tipo_cambio like '%5[0-9][0-9]' or tipo_cambio like '%5[0-9][0-9] ') and hospital_anterior like 'san%'
				then 'Piso'
			when tipo_cambio like '5%' or tipo_cambio like '%a 5%' or tipo_cambio like '%cambio 5%' or tipo_cambio like '%6[0-9][0-9]' or tipo_cambio like '%6[0-9][0-9] ' or tipo_cambio like '%5[0-9][0-9]' or tipo_cambio like '%5[0-9][0-9] '
				then 'Piso'
			when tipo_cambio like '%UTI' or tipo_cambio like '% a terapia'
				then 'UTI no especificado'
			when (tipo_cambio like '%piso%' or tipo_cambio like '%p[0-9]%' or tipo_cambio like '%a piso 4%') and tipo_cambio not like '%de piso%'
				then 'Piso'
			when tipo_cambio like '%de piso' or tipo_cambio like '%de piso '
				then 'Piso'
			when (tipo_cambio like '%6[0-9][0-9]%' and tipo_cambio not like '%de%6[0-9][0-9]%') or (tipo_cambio like '%6.%' and tipo_cambio not like '%de%6.%') or (tipo_cambio like '%5.%' and tipo_cambio not like '%de%5.%') or tipo_cambio like '%4.3%' and tipo_cambio not like '%de 4.3%'
				then 'Piso'
			when tipo_cambio like '%4h%' and tipo_cambio not like '%de 4h%'
				then 'Piso'
			when hospital_anterior like 'San%' and ((tipo_cambio like '% 3%' and tipo_cambio not like 'de 3%') or (tipo_cambio like '% 4%' and tipo_cambio not like 'de 4%'))
				then 'Piso'
			when hospital_anterior like 'Zam%' and (tipo_cambio like '%4[0-9][0-9]' or tipo_cambio like '%3[0-9][0-9]')
				then 'Piso'
			when tipo_cambio like 'Hospital Zambrano (414)' or tipo_cambio like 'Traslado hab102 '
				then 'Piso'
			when (tipo_cambio like '%emergencias%' or tipo_cambio like '%urgencias%' or tipo_cambio like '%urgenciaa%') and (tipo_cambio not like '%de%emergencias%' or tipo_cambio not like '%de%urgencias%')
				then 'Emergencias'
			when tipo_cambio like '%a intubacion%' or tipo_cambio like 'emergencia'
				then 'Emergencias'
			when tipo_cambio like '%imss%' or tipo_cambio like 'traslado' or tipo_cambio like 'Traslado ' or tipo_cambio like '%traslado%a%hospital%' or tipo_cambio like '%traslado%de%hospital%' or tipo_cambio like '%traslado hospital%' or tipo_cambio like '%traslado a HZH%' or tipo_cambio like '%transferencia' or tipo_cambio like '%trasladado' or tipo_cambio like '%de hospital%' or tipo_cambio like '% a clinica %' or tipo_cambio like 'Trasladado ' or tipo_cambio like 'trasladado'
				then 'Cambio de Hospital'
			when hospital_anterior like 'san%' and ((tipo_cambio like '%8[0-9][0-9]%' and tipo_cambio not like '%de 8[0-9][0-9]%') or (tipo_cambio like '%8.%' and tipo_cambio not like '%de 8.%') or (tipo_cambio like '%7[0-9][0-9]%' and tipo_cambio not like '%de%7[0-9][0-9]%') or (tipo_cambio like '%al 7%' and tipo_cambio not like '%de 7%' and tipo_cambio not like '%del 7%'))
				then 'Post-Terapia'
			when tipo_cambio like '% 7%' or tipo_cambio like '7' or tipo_cambio like '8' or tipo_cambio like '%7[0-9][0-9]' or tipo_cambio like '%8[0-9][0-9]'
				then 'Post-terapia'
			when tipo_cambio like 'cambio' or tipo_cambio like 'Cambio ' or tipo_cambio like 'cambio n%' or tipo_cambio like '%cambio%rea%'
				then 'Cambio no especificado'
			else 'Cambio no especificado'
		end as cambio,
		hospital_anterior
into tt04_altas_def
from [dbo].[tt03_altas_def]
where len(ID_paciente)<5
order by ID_paciente, ID_fecha
---------------------------------------------------------------------------------
-- DIM_estatus
---------------------------------------------------------------------------------
drop table dim_estatus
select [ID_paciente], [ID_fecha], [fecha_cambio], [hora_cambio], [cambio],
	case
		when cambio like 'Alta'
		then 1
		else 0
	end as Alta,
	case
		when cambio like 'UTIM' or cambio like 'UTIA' or cambio like 'UTI no especificado' or cambio like 'Emergencias'
		then 1
		else 0
	end as [Cuidados intensivos/Emergencias],
	case
		when cambio like 'Cambio de Hospital'
		then 1
		else 0
	end as [Cambio de hospital],
	case
		when cambio like 'Piso' or cambio like 'Post-Terapia'
		then 1
		else 0
	end as [Piso/Post-terapia],
	case
		when cambio like 'Defuncion'
		then 1
		else 0
	end as [Defunción],
	case
		when cambio like 'Alta'
			then '1'
		when cambio like 'UTIM'
			then '2'
		when cambio like 'Emergencias'
			then '3'
		when cambio like 'UTIA'
			then '4'
		when cambio like 'Cambio de Hospital'
			then '5'
		when cambio like 'Piso'
			then '6'
		when cambio like 'Cambio no especificado'
			then '7'
		when cambio like 'UTI no especificado'
			then '8'
		when cambio like 'Defuncion'
			then '9'
		when cambio like 'Post-Terapia'
			then '10'
	end as ID_estatus
into dim_estatus
from
(
	select row_number() over (partition by ID_paciente order by ID_paciente, ID_fecha desc, hora_cambio desc) as duptest,
	*
	from
	(
		select ID_paciente, ID_fecha, fecha_cambio, hora_cambio, cambio
		from tt04_altas_def
		where cambio not like 'cambio no especificado'
		group by ID_paciente, ID_fecha, fecha_cambio, cambio, hora_cambio
		--order by ID_fecha desc
	) t
) t
where duptest = 1

select distinct cambio from tt04_altas_def
