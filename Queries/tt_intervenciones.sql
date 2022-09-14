--------------------------------------------------------------------------------
-- Int_pacientes_fam
--------------------------------------------------------------------------------

select * from [dbo].[int_pacientes_fam]
-- son 7792 registros
where ID like '%[a-z.,-%&@#$*]%'

select * 
from [dbo].[int_pacientes_fam]
where try_Cast(ID as int) > 6000 or try_Cast(ID as int) is null
-- son 7 registros no validos

-- entonces aqui deben ser 7785, y lo son
select * 
from [dbo].[int_pacientes_fam]
where try_Cast(ID as int) < 6000 and try_Cast(ID as int) is not null

drop table tt01_intervenciones
select
		try_cast(b.correctID as int) as ID_paciente, c.ID_fecha, 
		convert(date,a.[Marca_temporal],23) as fecha,
		convert(time,a.[Marca_temporal],24) as hora
, a.[estrategias_paciente]
, a.[estrategias_fam]
, a.[hospital]
, a.[rehab_paciente]
, a.[tipo_intervencion]
, a.[tipo_seguimiento]
into tt01_intervenciones
from 
(
select * 
from [dbo].[int_pacientes_fam]
where try_Cast(ID as int) < 6000 and try_Cast(ID as int) is not null
) as a,
	[dbo].[CorrectIDs] as b,
	[dbo].[tt01_fechas] as c
where a.ID = b.ID and b.ID is not null and convert(date,a.[Marca_temporal],23) = c.fecha

-- tt01_intervenciones ya tiene ID_paciente y ID_fecha correctos

select distinct estrategias_paciente --, ID_paciente
from tt01_intervenciones 
where estrategias_paciente is not null
--order by ID_paciente

drop table tt02_intervenciones
select ID_paciente, ID_fecha, fecha, hora,
		case
			when [estrategias_paciente] like '%Valoraci�n cl�nica de rehabilitaci�n%'
			then '1' else '0'
		end as [Valoraci�n cl�nica de rehabilitaci�n],
		case
			when [estrategias_paciente] like '%sacerdote%' or [estrategias_paciente] like '%enlace religioso%'
			then '1' else '0'
		end as [Enlace religioso],
		case
			when [estrategias_paciente] like '%verbal%' or [estrategias_paciente] like '%en crisis%'
			then '1' else '0'
		end as [Intervenci�n en crisis],
		case
			when [estrategias_paciente] like '%psicoedu%'
			then '1' else '0'
		end as [Psicoeducaci�n],
		case
			when [estrategias_paciente] like '%actividades cognitivas'
			then '1' else '0'
		end as [Actividades cognitivas],
		case
			when [estrategias_paciente] like '%T�cnicas de relajaci�n%'
			then '1' else '0'
		end as [T�cnicas de relajaci�n],
		case
			when [estrategias_paciente] like 'Reestructuraci�n cognitiva'
			then '1' else '0'
		end as [Reestructuraci�n cognitiva],
		case
			when [estrategias_paciente] like '%tratamiento farmacol�gico%'
			then '1' else '0'
		end as [Tratamiento farmacol�gico],
		case
			when [estrategias_paciente] like '%tratamiento no farmacol�gico%'
			then '1' else '0'
		end as [Tratamiento no farmacol�gico],
		case
			when [estrategias_paciente] like '%Manejo no farmacol�gico de delirium%'
			then '1' else '0'
		end as [Manejo no farmacol�gico de delirium],
		case
			when [estrategias_paciente] like '%Manejo farmacol�gico de delirium%'
			then '1' else '0'
		end as [Manejo farmacol�gico de delirium],
		case
			when [estrategias_paciente] like '%Acompa�amiento%'
			then '1' else '0'
		end as [Acompa�amiento], [estrategias_fam], [rehab_paciente], [tipo_intervencion], [tipo_seguimiento]
into tt02_intervenciones
from [dbo].[tt01_intervenciones]
where estrategias_paciente is not null


