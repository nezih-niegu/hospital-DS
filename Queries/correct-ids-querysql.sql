-------------------------------------------------------------------------------------------------------------------------------------------
-- Despues de analizar nuestro dataset, es evidente que los registros de los pacientes por cada ingreso al hospital a veces se duplican, al ser
-- registrados de manera manual. Por lo tanto, el primer paso es limpiar la tabla de registro de pacientes, y reducirla a los IDs validos que
-- vamos a reemplazar en las tablas subsecuentes.

select * from correctIDs

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPIANDO IDS --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- tenemos 4044 registros, cada uno con un ID distinto
select * from [dbo].[pacientes]

-- hay que corregir los registros no validos
select * from [dbo].[pacientes]
where [numero_episodio] like '%[^0-9]%' or [numero_paciente] like '%[^0-9]%'  or [nombre_completo] = ''

-- con esto notamos que los registros 'raros' no estan repetidos, por lo que podemos usar sus IDs y sus datos no se pierden
select * from [dbo].[pacientes]
where ID in
(
select ID from [dbo].[pacientes]
where [numero_episodio] like '%[^0-9]%' or [numero_paciente] like '%[^0-9]%'  or [nombre_completo] = ''
)


select * from [dbo].[pacientes]
where nombre_completo in
(
select nombre_completo from [dbo].[pacientes]
where [numero_episodio] like '%[^0-9]%' or [numero_paciente] like '%[^0-9]%'  or [nombre_completo] = ''
)


 -- En teoria deberia de haber 1 1D por cada combinacion de numero de paciente, episodio y nombre .. pero al hacer este comando salen 3818 registros...
select [nombre_completo], [numero_paciente], [numero_episodio]
from [dbo].[pacientes]
group by [numero_episodio],[numero_paciente], [nombre_completo]

-- este codigo te da aparte un row number y un conteo de repeticion por los 4044 registros - lo cual nos ayudara en comandos siguientes
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number],
	*
	from [dbo].[pacientes]

--Con este comando sacamos que son 312 repetidos, ademas agregamos una columna de correctID para llenar despues

-- - Los ID que se toman son los primeros, entonces con este comando vamos a sacar esos IDs. Son 262 IDs que tienen extras.

select ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo]
from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number],
	*
	from [dbo].[pacientes]
	) t
where  StRank = 1 and [numero_episodio] in
		(
			select [numero_episodio]
			from
				(
				select row_number()
				over (partition by [numero_episodio], [numero_paciente]
				order by ID asc) as StRank, *
				from [dbo].[pacientes]
				) t
			where StRank <> 1
		) 


-- solo los que son StRank 1 (es decir, cuyo ID es valido)
select ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1

-- los que no son StRank 1 (es decir, los que son la segunda o mayor instancia de un paciente+episodio antes registrados)
select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from 
(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], NULL as correctID,
	*
	from [dbo].[pacientes]
) t
where StRank <> 1



-- junta las dos tablas anteriores de strank
-----  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID --- con nulos (los incorrectos)

select ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
		from 
		(
		select 
		row_number()
		over (partition by [numero_episodio], [numero_paciente]
		order by ID asc) as StRank, 
		row_number()
		over (order by [numero_episodio]) as [row_number], null as correctID,
		*
		from [dbo].[pacientes]
		) t
		where StRank <> 1
	)t
union
select ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1
	) t

-- Confirmando que nuestro codigo esta bien, checamos que tenga 4044 registros

select b.*, a.*
from
(
select  ID, [row_number] as row_2, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1
) as a,
(
select ID as lastID, [row_number] as row_1, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID as incorrectID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
		from 
		(
		select 
		row_number()
		over (partition by [numero_episodio], [numero_paciente]
		order by ID asc) as StRank, 
		row_number()
		over (order by [numero_episodio]) as [row_number], null as correctID,
		*
		from [dbo].[pacientes]
		) t
		where StRank <> 1
	)t
union
select ID, [row_number] as row_1, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID as incorrectID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
	from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1
	) t order by row_1
) as b
where (a.numero_episodio = b.numero_episodio and a.numero_paciente = b.numero_paciente) or (a.nombre_completo is null and b.nombre_completo is null) or (a.numero_episodio is null and b.numero_episodio is null and a.row_2 = b.row_1) or (a.numero_paciente is null and b.numero_paciente is null and a.row_2 = b.row_1)
order by [row_1], [row_2]

-- del codigo anterior.. tomo el last ID, y correct ID para poder corregir en otras tablas
-- realizaremos una nueva tabla para corregir los IDs en otras tablas posteriormente.. 

-- drop table CorrectIDs
select lastID as ID, correctID
into CorrectIDs
from
(
select cast(ID as int) as ID, [row_number] as row_2, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1 -- orderby ID
) as a,
(
select cast(ID as int) as lastID, [row_number] as row_1, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID as incorrectID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
		from 
		(
		select 
		row_number()
		over (partition by [numero_episodio], [numero_paciente]
		order by ID asc) as StRank, 
		row_number()
		over (order by [numero_episodio]) as [row_number], null as correctID,
		*
		from [dbo].[pacientes]
		) t
		where StRank <> 1
	)t
union
select cast(ID as int) as ID, [row_number] as row_1, StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID as incorrectID
from
	(
	select  ID, [row_number], StRank, [numero_episodio], [numero_paciente], [nombre_completo], correctID
	from 
	(
	select 
	row_number()
	over (partition by [numero_episodio], [numero_paciente]
	order by ID asc) as StRank, 
	row_number()
	over (order by [numero_episodio]) as [row_number], [ID] as correctID,
	*
	from [dbo].[pacientes]
	) t
where StRank = 1
	) t -- order by lastID
) as b 
where (a.numero_episodio = b.numero_episodio and a.numero_paciente = b.numero_paciente) or (a.nombre_completo is null and b.nombre_completo is null) or (a.numero_episodio is null and b.numero_episodio is null and a.row_2 = b.row_1) or (a.numero_paciente is null and b.numero_paciente is null and a.row_2 = b.row_1)
order by correctID
