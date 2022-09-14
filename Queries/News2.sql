------------------------------------------------------------------------------------
-- NEWS2 de TAMIZAJE
------------------------------------------------------------------------------------
select 
		[ID_fecha], [ID_paciente], [fecha], [hora], 
		[news2_traqueostomia], [news2_terapiaoxigeno], [news2_conciencia]
from [dbo].[tt04_tamizaje]

------------------------------------------------------------------------------------
-- NEWS2 de 4AT_CAMICU
------------------------------------------------------------------------------------
select
		ID_fecha, ID_paciente, fecha, hora, [news2_traqueostomia]
from [dbo].[tt02_4at_camicu]

------------------------------------------------------------------------------------
-- NEWS2 de NEWS2(st)
------------------------------------------------------------------------------------
select * from [dbo].[NEWS2]

drop table tt01_news2
select *
into tt01_news2
from [dbo].[NEWS2]
where ID like '[0-9]' or ID like '[0-9][0-9]' or ID like '[0-9][0-9][0-9]' or ID like '[0-9][0-9][0-9][0-9]'

select * from tt01_news2 where ID like '57'

select distinct frec_resp from tt01_news2
where frec_resp like '%[^0-9]%' and frec_resp not like '%min%'

select distinct frec_resp from tt01_news2
where frec_resp like '%min%'

select distinct sat_oxigeno from tt01_news2
where sat_oxigeno like '%[^0-9]%'

select distinct pa_diastolica from tt01_news2
where pa_diastolica like '%[^0-9/ ]%'

select distinct pa_diastolica from tt01_news2
where pa_diastolica like '%/%'

select distinct pa_sistolica from tt01_news2
where pa_sistolica like '%/%'

select distinct pa_sistolica from tt01_news2
where pa_sistolica like '%[^0-9/ ]%'

select distinct frec_cardiaca from tt01_news2
where frec_cardiaca like '%[^0-9]%'

drop table tt02_news2
select b.correctID as ID_paciente, c.ID_fecha as ID_fecha
		,convert(date,[Marca_temporal],23) as fecha
		,convert(time,marca_temporal,24) as hora,
		case
			when a.frec_resp like '%[^0-9]%' and a.frec_resp not like '%min%' or len(a.frec_resp) >2
				then null
			when a.frec_resp like '%min%'
				then left(a.frec_resp,2)
			else a.frec_resp
		end as frec_resp,
		case
			when a.[sat_oxigeno] like '%[^0-9]%' 
				then null
			else a.sat_oxigeno
		end as [sat_oxigeno],
		case 
			when a.[pa_sistolica] like '%[^0-9/ ]%'
				then null
			when a.pa_sistolica like '[0-9][0-9]/%'
				then left(a.pa_sistolica,2)
			when a.pa_sistolica like '[0-9][0-9][0-9]/%'
				then left(a.pa_sistolica,3)
			when a.pa_diastolica like '[0-9][0-9]/%'
				then left(a.pa_diastolica,2)
			when a.pa_diastolica like '[0-9][0-9][0-9]/%'
				then left(a.pa_diastolica,3)
			else a.pa_sistolica
		end as [pa_sistolica],
		case
			when a.[pa_diastolica] like '%[^0-9/ ]%'
				then null
			when a.pa_sistolica like '%/[0-9][0-9]'
				then right(a.pa_sistolica,2)
			when a.pa_sistolica like '%/[0-9][0-9][0-9]'
				then right(a.pa_sistolica,3)
			when a.pa_diastolica like '%/[0-9][0-9]'
				then right(a.pa_diastolica,2)
			when a.pa_diastolica like '%/[0-9][0-9][0-9]'
				then left(a.pa_diastolica,3)
			else a.pa_diastolica
		end as [pa_diastolica],
		case 
			when a.[frec_cardiaca] like '%[^0-9]%'  
				then null
			else a.frec_cardiaca
		end as [frec_cardiaca]
, a.[EPOC],
		case 
			when [temperatura_c] like '%[3-4][0-9]%' or temperatura_c like '[3-4][0-9].' or temperatura_c like '[3-4][0-9].[0-9]' 
			then [temperatura_c] 
			else null
		end as [temperatura_c], a.[hospital]
into tt02_news2
from [dbo].[tt01_news2] as a, [dbo].[correctIDs] as b, [dbo].[tt01_fechas] as c
where a.ID = b.ID and convert(date,a.[Marca_temporal],23) = c.fecha

drop table tt03_news2
select cast(ID_paciente as int) as ID_paciente, ID_fecha, fecha, hora, 
		cast([frec_resp] as int) as [frec_resp],
		cast([sat_oxigeno] as int) as [sat_oxigeno],
		cast([pa_sistolica] as int) as [pa_sistolica],
		cast([pa_diastolica] as int) as [pa_diastolica],
		cast([frec_cardiaca] as int) as [frec_cardiaca],
[EPOC], [temperatura_c], [hospital]
into tt03_news2
from tt02_news2

------------------------------------------------------------------------------------
select a.*, b.news2_traqueostomia, c.[news2_traqueostomia] as traqueo, c.[news2_terapiaoxigeno], c.[news2_conciencia]
from [dbo].[tt03_news2] as a,
(
select
		ID_fecha, ID_paciente, fecha, hora, [news2_traqueostomia]
from [dbo].[tt02_4at_camicu]
) as b,
(
select 
		[ID_fecha], [ID_paciente], [fecha], [hora], 
		[news2_traqueostomia], [news2_terapiaoxigeno], [news2_conciencia]
from [dbo].[tt04_tamizaje]
) as c
where a.ID_paciente = b.ID_paciente and a.ID_paciente = c.ID_paciente and (a.ID_fecha = c.ID_fecha or a.ID_fecha = b.ID_fecha)
-- aqui nos damos cuenta que no necesitamos la columna de traqueostomia de 4at o de tamizaje
-- porque hay muchas instancias en las que esta incorrecto, se pueden tomar los valores del news2 base
-- por lo tanto, no necesitamos el news2 de la tabla de 4at, porque es la unica columna de news que tiene esa tabla
-- entonces nuestro codigo queda asi

select a.*, c.[news2_terapiaoxigeno], c.[news2_conciencia]
from [dbo].[tt03_news2] as a,
(
select 
		[ID_fecha], [ID_paciente], [fecha], [hora], [news2_terapiaoxigeno], [news2_conciencia]
from [dbo].[tt04_tamizaje]
) as c
where a.ID_paciente = c.ID_paciente and a.ID_fecha = c.ID_fecha


select *, null as news2_terapiaoxigeno, null as news2_conciencia
from tt03_news2

-- ahora unimos los datos que tenemos

drop table tt04_news2
select * 
--into tt04_news2
from
(
select a.*, c.[news2_terapiaoxigeno], c.[news2_conciencia]
from [dbo].[tt03_news2] as a,
(
select 
		[ID_fecha], [ID_paciente], [fecha], [hora], [news2_terapiaoxigeno], [news2_conciencia]
from [dbo].[tt04_tamizaje]
) as c
where a.ID_paciente = c.ID_paciente and a.ID_fecha = c.ID_fecha
union 
select *, null as news2_terapiaoxigeno, null as news2_conciencia
from tt03_news2
) t

select * from tt03_news2

select * from tt04_news2 order by ID_paciente, ID_fecha
