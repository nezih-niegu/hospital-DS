------------------------------------------------------------------------------------
-- Crear una dimension de tiempo
------------------------------------------------------------------------------------
-- Formato de FECHA que usa la base de datos fuente
-- 23	select convert(varchar, getdate(), 23)	yyyy-mm-dd	2006-12-30
-- Formato de HORA que usa la base de datos fuente
-- 24	select convert(varchar, getdate(), 24)	hh:mm:ss	00:38:54
------------------------------------------------------------------------------------
-- Los datos que tenemos se supone empiezan en 2020, pero, por si acaso, queremos tener IDs
-- para fechas desde el año 2018. 

drop table tt_fechas
			DECLARE @StartDate  date = '20180101';
			DECLARE @CutoffDate date = DATEADD(DAY, -1, DATEADD(YEAR, 5, @StartDate));

			;WITH seq(n) AS 
			(
			  SELECT 0 UNION ALL SELECT n + 1 FROM seq
			  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
			),
			d(d) AS 
			(
			  SELECT DATEADD(DAY, n, @StartDate) FROM seq
			),
			src AS
			(
			  SELECT
				Fecha         = CONVERT(date, d),
				Dia          = DATEPART(DAY,       d),
				DiaNombre      = DATENAME(WEEKDAY,   d),
				Semana         = DATEPART(WEEK,      d),
				DiaSemana    = DATEPART(WEEKDAY,   d),
				Mes        = DATEPART(MONTH,     d),
				MesNombre    = DATENAME(MONTH,     d),
				Cuarto      = DATEPART(Quarter,   d),
				[Year]         = DATEPART(YEAR,      d),
				PrimerMes = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
				TheLastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
				TheDayOfYear    = DATEPART(DAYOFYEAR, d)
			  FROM d
			)
			SELECT * 
			into tt_fechas
			FROM src
			  ORDER BY Fecha
			  OPTION (MAXRECURSION 0);

select * from tt_fechas

drop table tt01_fechas
select row_number() over (order by a.fecha) as ID_fecha, a.*
into tt01_fechas
from [dbo].[tt_fechas] as a

select * from tt01_fechas
------------------------------------------------------------------------------------
-- Podríamos incluir un ID de hora..., but maybe that's overkill.

			DECLARE @starthour  time = '00:00:00';
			DECLARE @cutoffhour time = DATEADD(second, -1, DATEADD(hour, 24, @starthour));

			;WITH seq(n) AS 
			(
			  SELECT 0 UNION ALL SELECT n + 1 FROM seq
			  WHERE n < DATEDIFF(second, @starthour, @cutoffhour)
			),
			d(d) AS 
			(
			  SELECT DATEADD(second, n, @starthour) FROM seq
			),
			src AS
			(
			  SELECT
			  Tiempo		= convert(time, d),
			  Hora			= datepart(hour,	d),
			  Minuto		= datepart(minute,	d),
			  Segundo		= datepart(second,	d)
			  FROM d
			)
			SELECT * 
			FROM src
			  ORDER BY Tiempo
			  OPTION (MAXRECURSION 0);