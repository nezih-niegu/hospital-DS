select *
into tt01_hospital
from
(
select a.ID_paciente, b.hospital as hospital
from tt04_pacientes as a
full outer join
[dbo].[tt_hospital] as b
on a.ID_paciente = b.ID_paciente
) t



drop table FT_Registro
select row_number() over (order by a.ID_paciente, b.ID_fecha) as Registro, c.hospital as hospital_ingreso, a.ID_paciente, b.[ID_fecha]
into FT_registro
from tt04_pacientes as a, [dbo].[tt01_fechas] as b, [dbo].[tt01_hospital] as c
where a.ID_paciente = c.ID_paciente



select a.registro, b.hora, b.[frec_resp], b.[sat_oxigeno], b.[pa_sistolica], b.[pa_diastolica], b.[frec_cardiaca], b.[EPOC], b.[temperatura_c]
into DIM_NEWS2
from FT_registro as a, [dbo].[tt04_news2] as b
where a.ID_fecha = b.ID_fecha and a.ID_paciente = b.ID_paciente

select a.registro, b.[hora_cambio], [cambio]
into DIM_AltasDef
from FT_registro as a, [dbo].[tt04_altas_def] as b
where a.ID_fecha = b.ID_fecha and a.ID_paciente = b.ID_paciente

select a.registro, b.[hora] , b.[Valoración clínica de rehabilitación] , b.[Enlace religioso] , b.[Intervención en crisis] , b.[Psicoeducación] , b.[Actividades cognitivas],
b.[Técnicas de relajación], b.[Reestructuración cognitiva] , b.[Tratamiento farmacológico] , b.[Tratamiento no farmacológico] , b.[Manejo no farmacológico de delirium] ,
b.[Acompañamiento] , b.[estrategias_fam] , b.[rehab_paciente] , b.[tipo_intervencion] , b.[tipo_seguimiento]
--into DIM_intervenciones
from FT_registro as a, [dbo].[tt02_intervenciones] as b
where a.ID_fecha = b.ID_fecha and a.ID_paciente = b.ID_paciente

select * from [dbo].[tt02_intervenciones]


drop table DIM_delirium
select a.registro, b.[hora], b.[delirium], b.[delirium_test],
		case
			when delirium like 'Delirium unlikely' then '1' else '0'
		end as [Delirium unlikely],
		case
			when delirium like 'Possible cognitive impairment' then '1' else '0'
		end as [Possible cognitive impairment],
		case
			when delirium like 'Delirium likely' then '1' else '0'
		end as [Delirium likely]
into DIM_delirium
from FT_registro as a, [dbo].[tt_delirium] as b
where a.ID_fecha = b.ID_fecha and a.ID_paciente = b.ID_paciente

select * from dim_delirium

drop table DIM_pacientes
select b.*
into DIM_pacientes
from [dbo].[tt04_pacientes] as b


drop table DIM_fecha
select b.*
into DIM_fecha
from  [dbo].[tt01_fechas] as b

drop table DIM_residencia
select [ID_paciente], 
case
	when [residencia_pais] like 'Estados%' then 'United States'
	when [residencia_pais] like 'Honduras' then 'Honduras'
	when [residencia_pais] like 'M%xico' then 'Mexico'
	when [residencia_pais] like 'Puerto Rico' then 'Puerto Rico'
	when [residencia_pais] like 'Ital%' then 'Italy'
end as [País], 
[residencia_estado] as [Estado]
into DIM_residencia
from tt04_pacientes

select distinct [residencia_pais] from [dbo].[tt04_pacientes]