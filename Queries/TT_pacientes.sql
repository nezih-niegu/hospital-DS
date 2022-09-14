-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------- Tabla Pacientes ----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select * from [dbo].[pacientes]

select * from
(
select a.correctID
, b. marca_temporal
, b.[fecha_ingreso]
, b.[hora_ingreso_24hrs]
, b.[numero_paciente]
, b.[numero_episodio]
, b.[edad]
, b.[sexo]
, b.[fecha_nacimiento]
, b.[cuarto_cubiculo_actual]
, b.[estado_civil]
, b.[religion]
, b.[residencia]
, b.[educacion]
, b.[ocupacion]
, b.[peso_ingreso_kg]
, b.[talla_ingreso_cm]
, b.[diagnostico_paciente]
, b.[hospital]
, b.[registrador_paciente]
from [dbo].[pacientes] as b, [dbo].[CorrectIDs] as a
where a.ID = b.ID
) t

-- ahora reducimos el registro de pacientes ya que es inevitable que algunos de los registros esten duplicados, por lo que solo hay que eliminarlos
-- quitamos la columna de ID pasado, realizamos una tt sin los nombres de los pacientes y ya! terminamos de reemplazar la primera tabla de ID

drop table tt01_pacientes
select cast(correctID as int) as ID_paciente
, [marca_temporal ] as marca_temporal
, [fecha_ingreso]
, [hora_ingreso_24hrs]
, [sexo]
, [fecha_nacimiento]
, [edad]
, [peso_ingreso_kg]
, [talla_ingreso_cm]
, [estado_civil]
, [religion]
, [residencia]
, [educacion]
, [ocupacion]
, [cuarto_cubiculo_actual]
, [diagnostico_paciente]
, [hospital]
, [registrador_paciente]
into tt01_pacientes
from 
(
	select row_number()
	over (partition by correctID
	order by marca_temporal asc) as duplicates, *
	from 
	(
		select * from
			(
				select a.correctID
				, b. marca_temporal
				, b.[fecha_ingreso]
				, b.[hora_ingreso_24hrs]
				, b.[numero_paciente]
				, b.[numero_episodio]
				, b.[edad]
				, b.[sexo]
				, b.[fecha_nacimiento]
				, b.[cuarto_cubiculo_actual]
				, b.[estado_civil]
				, b.[religion]
				, b.[residencia]
				, b.[educacion]
				, b.[ocupacion]
				, b.[peso_ingreso_kg]
				, b.[talla_ingreso_cm]
				, b.[diagnostico_paciente]
				, b.[hospital]
				, b.[registrador_paciente]
				from [dbo].[pacientes] as b, [dbo].[CorrectIDs] as a
				where a.ID = b.ID
			) t
	) t
) t
where duplicates = 1

--Ya que tenemos los ID, aun tenemos que limpiar el resto de las columnas de la tabla de registro de pacientes

-- De aqui en adelante, debemos tener 3732 registros en tt01_pacientes
select * from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- Fecha de Ingreso --
-------------------------------------------------------------------------------------------------------------------
select distinct(fecha_ingreso) from tt01_pacientes

select
		case
			when [fecha_ingreso] like '00%'
			then '20'+ right([fecha_ingreso],8)
			when [fecha_ingreso] like '202[2-9]%'
			then '2021'+right(fecha_ingreso,6)
			when [fecha_ingreso] like '19%'
			then null
			when fecha_ingreso like '02%'
			then null
			else [fecha_ingreso]
		end as [fecha_ingreso]
from [dbo].[tt01_pacientes]

-------------------------------------------------------------------------------------------------------------------
-- Hora  de Ingreso --
-------------------------------------------------------------------------------------------------------------------

select distinct(hora_ingreso_24hrs) from tt01_pacientes

-- 00:00:00

	select
		case
			when [hora_ingreso_24hrs] like '[0-9]:%' and [hora_ingreso_24hrs] like '%a%'
			then '0'+left([hora_ingreso_24hrs],7)
			when [hora_ingreso_24hrs] like '[0-9][0-9]:%' and [hora_ingreso_24hrs] like '%a%'
			then left([hora_ingreso_24hrs],8)
			when [hora_ingreso_24hrs] like '[0-9]:%' and [hora_ingreso_24hrs] like '%p%'
			then cast((cast((left([hora_ingreso_24hrs],1)) as int))+12 as varchar) +substring([hora_ingreso_24hrs],2,6)
			when [hora_ingreso_24hrs] like '[0-9][0-9]:%' and [hora_ingreso_24hrs] like '%p%' and [hora_ingreso_24hrs] not like '12%'
			then (cast((cast((left([hora_ingreso_24hrs],2)) as int))+12 as varchar))+substring([hora_ingreso_24hrs],3,6)
			when [hora_ingreso_24hrs] like '12:%' and [hora_ingreso_24hrs] like '%p%'
			then '12'+substring([hora_ingreso_24hrs],3,6)
			else [hora_ingreso_24hrs]
		end as hora_ingreso
	from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- sexo --
-------------------------------------------------------------------------------------------------------------------
select distinct(sexo) from tt01_pacientes
-- este caso tiene que ser correccion manual, asi que buscamos el nombre, y corregimos
select * from pacientes where ID in
(
select ID_paciente from tt01_pacientes
where sexo is null
) 
-- el paciente 117 es masculino
select ID_paciente,
		case
		when ID_paciente = 117
		then 'Masculino'
		else sexo
		end as sexo
from tt01_pacientes

select * from correctIDs where ID = 303 or correctID = 303
-- con esto nos damos cuenta que el registro 303 es perdido porque no tiene nada registrado

-------------------------------------------------------------------------------------------------------------------
-- Fecha de nacimiento y edad
-------------------------------------------------------------------------------------------------------------------
select distinct([fecha_nacimiento]) from tt01_pacientes

select distinct(edad) from tt01_pacientes

select * from tt01_pacientes where ID_paciente = 35

select ID_paciente,
		case
			when edad is null and abs(age - edad)<10 or len(edad)>2
			then age
			else edad
		end as edad_years, 
		case
		when months>0
		then months
		when months<0
		then cast(months as int)+11
		else months
		end as edad_meses,
		case
			when edad is not null and abs(age - edad)<10
			then fecha_nacimiento
			when edad is not null and edad <> age and ((edad - age)>10 or (age - edad)>10) and ((edad - age)<50)
			then 
				convert(
				date, 
					(
						cast(year(dateadd(year,-(cast(edad as int)),[marca_temporal]))as varchar)
						+'-'+
						cast(month([fecha_nacimiento])as varchar)
						+'-'+
						cast(day([fecha_nacimiento]) as varchar)
					)
				, 23)
			else fecha_nacimiento
		end as fecha_nacimiento
from
	(
	select fecha_nacimiento, marca_temporal, ID_paciente, edad, datediff(month,[birthday],[marca_temporal])/12 as age, 
	datediff(month,birthday,[marca_temporal])-((datediff(month,birthday,[marca_temporal])/12)*12) as months
	from 
		(
		select
				case
					when [fecha_nacimiento] like '00%'
					then dateadd(year,1900,[fecha_nacimiento])
					when fecha_nacimiento like '1[0-8]%'
					then dateadd(year, ((9-cast(substring(cast(year([fecha_nacimiento]) as varchar),2,1) as int))*100),[fecha_nacimiento])
					when year(fecha_nacimiento)>2021
					then dateadd(year,-1000,[fecha_nacimiento])
					else [fecha_nacimiento]
				end as birthday,
				case
					when edad like '%[^0-9]%'
					then null
					else edad
				end as edad,
				ID_paciente, marca_temporal, fecha_nacimiento
		from tt01_pacientes
		) t
	) t order by ID_paciente

-------------------------------------------------------------------------------------------------------------------
-- peso_ingreso_kg
-------------------------------------------------------------------------------------------------------------------
select distinct(peso_ingreso_kg) from tt01_pacientes

select peso_ingreso_kg from tt01_pacientes
where peso_ingreso_kg like '%[0-9]%' and peso_ingreso_kg like '%[a-z][a-z]%'

select peso_ingreso_kg
from tt01_pacientes
where peso_ingreso_kg not like '%[0-9]%'


select ID_paciente,
		case
			when peso_ingreso_kg not like '%[0-9]%'
				then null
			when peso_ingreso_kg like '%[0-9]%' and peso_ingreso_kg like '%[a-z]%'
				then trim(' kg' from peso_ingreso_kg)
			else peso_ingreso_kg
		end as peso_ingreso_kg
from tt01_pacientes
-------------------------------------------------------------------------------------------------------------------
-- Talla_ingreso_cm
-------------------------------------------------------------------------------------------------------------------
select distinct(talla_ingreso_cm)
from tt01_pacientes

select ID_paciente,
		case
			when talla_ingreso_cm not like '%[0-9]%'
				then null
			when talla_ingreso_cm like '%[0-9]%' and talla_ingreso_cm like '%[.,]%' and len(talla_ingreso_cm)>3
				then left(talla_ingreso_cm,1)+right(talla_ingreso_cm,2)
			when talla_ingreso_cm like '%[0-9]%' and talla_ingreso_cm like '%[.,]%' and len(talla_ingreso_cm)<4
				then left(talla_ingreso_cm,1)+right(talla_ingreso_cm,1)+'0'
			else talla_ingreso_cm
		end as talla_ingreso_cm
from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- Estado civil
-------------------------------------------------------------------------------------------------------------------
select distinct(estado_civil)
from tt01_pacientes
-- Se queda igual
-------------------------------------------------------------------------------------------------------------------
-- Religion
-------------------------------------------------------------------------------------------------------------------
select distinct(religion)
from tt01_pacientes
where religion like '[^a-z0-9]'

select ID_paciente,
		case
			when religion like 'Sin%' or religion like 'no%' or religion like 'ning%'
				then 'Ninguno'
			when religion like '%[0-9]%' or religion like '[a-z]' or religion like '[^a-z,0-9]' or religion like '%"%' or religion like '.' or religion like 'NA'
				then null
			when religion like 'testig%'
				then 'Testigo de Jehová'
			when religion like 'morm%'
				then 'Mormón'
			when religion like 'Evangel%'
				then 'Evangélico'
			else religion
		end as religion
from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- Residencia
-------------------------------------------------------------------------------------------------------------------
select distinct(residencia) from tt01_pacientes

select ID_paciente,
		case
			when residencia like 'otro municipio%' or residencia like 'Mty o Zona%' or residencia like 'Nuevo León' or residencia like 'Garc%' or residencia like 'Linares'
				then 'Nuevo León'
			when residencia like 'Celaya'
				then 'Guanajuato'
			when residencia like 'Chihuahua' or residencia like 'Chiapas' or residencia like 'Tabasco' or residencia like 'Hidalgo' or residencia like 'Zacatecas'
				or residencia like 'San Luis Potosí' or residencia like 'Tamaulipas' or residencia like 'Ciudad de México' or residencia like 'Guerrero'
				or residencia like 'Michoacán' or residencia like 'Puebla' or residencia like 'Sinaloa' or residencia like 'Durango' or residencia like 'Sonora'
				or residencia like 'Quintana Roo' or residencia like 'Oaxaca' or residencia like 'Baja%' or residencia like 'Quer' or residencia like 'Veracruz'
				or residencia like 'Jalisco'
				then residencia
			when residencia like 'Montemorelos' or residencia like 'Cadereyta'
				then 'Nuevo León'
			when residencia like 'Saltillo'
				then 'Coahuila'
			when residencia like 'México'
				then 'Ciudad de México'
			when residencia like 'Roma%'
				then 'Roma'
			when residencia like 'sabinas%'
				then 'Hidalgo'
			when residencia like 'Houston' or residencia like 'Texas'
				then 'Texas'
			when residencia like 'Gexto'
				then 'Vizcaya'
			when residencia like 'Nuevo Laredo'
				then 'Tamaulipas'
			else null
		end as residencia_estado,
		case
			when residencia like 'Houston' or residencia like 'Estados Unidos'
				then 'Estados Unidos'
			when residencia like 'Gexto'
				then 'España'
			when residencia like 'Honduras'
				then residencia
			when residencia like 'Roma%'
				then 'Italia'
			when residencia like 'San Juan%'
				then 'Puerto Rico'
			else 'México'
		end as residencia_pais,
		case
			when residencia like 'Mty o Zona%' or residencia like 'Garc%'
				then 'Mty o Zona Metropolitana'
			when residencia like 'otro municipio%' or residencia like 'Nuevo León' or residencia like 'Linares'
				then 'Otro municipio NL'
			when residencia not like 'Mty o Zona%' and residencia not like 'Garc%' and residencia not like 'otro municipio%' and residencia not like 'Nuevo León' and residencia not like 'Linares' and residencia is not null
				then 'Foraneo'
		end as residencia_NL
from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- Educacion
-------------------------------------------------------------------------------------------------------------------
select distinct([educacion]) from tt01_pacientes
-- se queda igual
-------------------------------------------------------------------------------------------------------------------
-- Ocupacion
-------------------------------------------------------------------------------------------------------------------
select distinct([ocupacion]) from tt01_pacientes order by ocupacion


select ID_paciente,
		case
			when ocupacion like 'pension%' or ocupacion like 'jubil%'
				then 'Jubilado o Pensionado'
			when ocupacion like '%M%dico%'  or ocupacion like 'pedia%' or ocupacion like 'doct'
				then 'Medico'
			when ocupacion like 'abog%'
				then 'Abogado'
			when ocupacion like '%-%' or ocupacion like '%.%' or ocupacion is null or ocupacion like 'no %'
				then null
			when ocupacion like 'admin%'
				then 'Administrativo'
			when ocupacion like 'bienes%'
				then 'Bienes raíces'
			when ocupacion like 'ama de%' or ocupacion like 'espos%'  or ocupacion like 'hoga%'
				then 'Hogar'
			when ocupacion like 'cont%'
				then 'Contaduría'
			when ocupacion like 'desempl' or ocupacion like 'ning'
				then 'Desempleado'
			when ocupacion like 'maestr%'
				then 'Maestra'
			when ocupacion like 'niñ%de%años' or [ocupacion] like 'lactan%'
				then 'NA'
			when ocupacion like 'polic%'
				then 'Policía'
			when ocupacion like 'Tecnico'
				then 'Técnico'
			when ocupacion like 'vend%' or ocupacion like 'vent%'
				then 'Ventas'
			when ocupacion like 'empres%' or ocupacion like 'negocio%'
				then 'Empresario'
			when ocupacion like 'geren%'
				then 'Gerente'
			else ocupacion
		end as ocupacion
from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- Cuarto_cubiculo_actual y Hospital
-------------------------------------------------------------------------------------------------------------------
select distinct([cuarto_cubiculo_actual]) from tt01_pacientes
select distinct([hospital]) from tt01_pacientes
-- se quedan igual

-------------------------------------------------------------------------------------------------------------------
-- diagnostico_paciente
-------------------------------------------------------------------------------------------------------------------
select distinct([diagnostico_paciente]) from tt01_pacientes
-- se quedan igual
-------------------------------------------------------------------------------------------------------------------
-- registrador_paciente
-------------------------------------------------------------------------------------------------------------------
select distinct([registrador_paciente]) from tt01_pacientes order by registrador_paciente

select ID_paciente,
		case
			when registrador_paciente like 'Juan M%'
				then 'Juan Manuel'
			when registrador_paciente like 'Miguel%'
				then 'Miguel'
			when registrador_paciente like 'Sam%'
				then 'Samantha'
			when registrador_paciente like 'Steph%'
				then 'Stephanía'
			when registrador_paciente like 'sof%'
				then 'Sofia'
			when registrador_paciente like 'V%ctor%'
				then 'Víctor'
			when registrador_paciente like 'Laur%'
				then 'Laura'
			when registrador_paciente like 'Priscy%'
				then 'Priscyla'
			else registrador_paciente
		end as registrador_paciente
from tt01_pacientes

-------------------------------------------------------------------------------------------------------------------
-- TODO JUNTO 
-------------------------------------------------------------------------------------------------------------------
drop table tt02_pacientes
select a. ID_paciente, a.marca_temporal, b.fecha_ingreso, c.hora_ingreso, d.sexo, e.fecha_nacimiento, e.edad_years, e.edad_meses,
		f.peso_ingreso_kg, g.talla_ingreso_cm, a.estado_civil, h.religion, i.residencia_pais, i.residencia_estado, 
		i.residencia_NL, a.educacion, j.ocupacion, a.cuarto_cubiculo_actual, a.diagnostico_paciente, a.hospital, k.registrador_paciente
into tt02_pacientes
from tt01_pacientes as a,
	(
		select ID_paciente,
			case
				when [fecha_ingreso] like '00%'
				then '20'+ right([fecha_ingreso],8)
				when [fecha_ingreso] like '202[2-9]%'
				then '2021'+right(fecha_ingreso,6)
				when [fecha_ingreso] like '19%'
				then null
				when fecha_ingreso like '02%'
				then null
				when fecha_ingreso like '2001%'
				then '2021'+right(fecha_ingreso,6)
				when fecha_ingreso like '2011%'
				then '2021'+right(fecha_ingreso,6)
				else [fecha_ingreso]
			end as [fecha_ingreso]
		from [dbo].[tt01_pacientes]
	) as b,
	(
		select ID_paciente,
			case
				when [hora_ingreso_24hrs] like '[0-9]:%' and [hora_ingreso_24hrs] like '%a%'
				then '0'+left([hora_ingreso_24hrs],7)
				when [hora_ingreso_24hrs] like '[0-9][0-9]:%' and [hora_ingreso_24hrs] like '%a%'
				then left([hora_ingreso_24hrs],8)
				when [hora_ingreso_24hrs] like '[0-9]:%' and [hora_ingreso_24hrs] like '%p%'
				then cast((cast((left([hora_ingreso_24hrs],1)) as int))+12 as varchar) +substring([hora_ingreso_24hrs],2,6)
				when [hora_ingreso_24hrs] like '[0-9][0-9]:%' and [hora_ingreso_24hrs] like '%p%' and [hora_ingreso_24hrs] not like '12%'
				then (cast((cast((left([hora_ingreso_24hrs],2)) as int))+12 as varchar))+substring([hora_ingreso_24hrs],3,6)
				when [hora_ingreso_24hrs] like '12:%' and [hora_ingreso_24hrs] like '%p%'
				then '12'+substring([hora_ingreso_24hrs],3,6)
				else [hora_ingreso_24hrs]
			end as hora_ingreso
		from tt01_pacientes
	) as c,
	(
		select ID_paciente,
			case
			when ID_paciente = 117
			then 'Masculino'
			else sexo
			end as sexo
		from tt01_pacientes
	) as d,
	(
		select ID_paciente,
				case
					when edad is null and abs(age - edad)<10 or len(edad)>2
					then age
					else edad
				end as edad_years, 
				case
				when months>0
				then months
				when months<0
				then cast(months as int)+11
				else months
				end as edad_meses,
				case
					when edad is not null and abs(age - edad)<10
					then fecha_nacimiento
					when edad is not null and edad <> age and ((edad - age)>10 or (age - edad)>10) and ((edad - age)<50)
					then 
						convert(
						date, 
							(
								cast(year(dateadd(year,-(cast(edad as int)),[marca_temporal]))as varchar)
								+'-'+
								cast(month([fecha_nacimiento])as varchar)
								+'-'+
								cast(day([fecha_nacimiento]) as varchar)
							)
						, 23)
					else fecha_nacimiento
				end as fecha_nacimiento
		from
		(
			select fecha_nacimiento, marca_temporal, ID_paciente, edad, datediff(month,[birthday],[marca_temporal])/12 as age, 
			datediff(month,birthday,[marca_temporal])-((datediff(month,birthday,[marca_temporal])/12)*12) as months
			from 
				(
				select
						case
							when [fecha_nacimiento] like '00%'
							then dateadd(year,1900,[fecha_nacimiento])
							when fecha_nacimiento like '1[0-8]%'
							then dateadd(year, ((9-cast(substring(cast(year([fecha_nacimiento]) as varchar),2,1) as int))*100),[fecha_nacimiento])
							when year(fecha_nacimiento)>2021
							then dateadd(year,-1000,[fecha_nacimiento])
							else [fecha_nacimiento]
						end as birthday,
						case
							when edad like '%[^0-9]%'
							then null
							else edad
						end as edad,
						ID_paciente, marca_temporal, fecha_nacimiento
				from tt01_pacientes
				) t
		) t 
	) as e,
	(
		select ID_paciente,
			case
				when peso_ingreso_kg not like '%[0-9]%'
					then null
				when peso_ingreso_kg like '%[0-9]%' and peso_ingreso_kg like '%[a-z]%'
					then trim(' kg' from peso_ingreso_kg)
				else peso_ingreso_kg
			end as peso_ingreso_kg
		from tt01_pacientes
	) as f,
	(
		select ID_paciente,
			case
				when talla_ingreso_cm not like '%[0-9]%'
					then null
				when talla_ingreso_cm like '%[0-9]%' and talla_ingreso_cm like '%[.,]%' and len(talla_ingreso_cm)>3
					then left(talla_ingreso_cm,1)+right(talla_ingreso_cm,2)
				when talla_ingreso_cm like '%[0-9]%' and talla_ingreso_cm like '%[.,]%' and len(talla_ingreso_cm)<4
					then left(talla_ingreso_cm,1)+right(talla_ingreso_cm,1)+'0'
				else talla_ingreso_cm
			end as talla_ingreso_cm
		from tt01_pacientes
	) as g,
	(
		select ID_paciente,
			case
				when religion like 'Sin%' or religion like 'no%' or religion like 'ning%'
					then 'Ninguno'
				when religion like '%[0-9]%' or religion like '[a-z]' or religion like '[^a-z,0-9]' or religion like '%"%' or religion like '.' or religion like 'NA'
					then null
				when religion like 'testig%'
					then 'Testigo de Jehová'
				when religion like 'morm%'
					then 'Mormón'
				when religion like 'Evangel%'
					then 'Evangélico'
				else religion
			end as religion
		from tt01_pacientes
	) as h,
	(
		select ID_paciente,
			case
				when residencia like 'otro municipio%' or residencia like 'Mty o Zona%' or residencia like 'Nuevo León' or residencia like 'Garc%' or residencia like 'Linares'
					then 'Nuevo León'
				when residencia like 'Celaya'
					then 'Guanajuato'
				when residencia like 'Chihuahua' or residencia like 'Chiapas' or residencia like 'Tabasco' or residencia like 'Hidalgo' or residencia like 'Zacatecas'
					or residencia like 'San Luis Potosí' or residencia like 'Tamaulipas' or residencia like 'Ciudad de México' or residencia like 'Guerrero'
					or residencia like 'Michoacán' or residencia like 'Puebla' or residencia like 'Sinaloa' or residencia like 'Durango' or residencia like 'Sonora'
					or residencia like 'Quintana Roo' or residencia like 'Oaxaca' or residencia like 'Baja%' or residencia like 'Quer' or residencia like 'Veracruz'
					or residencia like 'Jalisco'
					then residencia
				when residencia like 'Montemorelos' or residencia like 'Cadereyta'
					then 'Nuevo León'
				when residencia like 'Saltillo'
					then 'Coahuila'
				when residencia like 'México'
					then 'Ciudad de México'
				when residencia like 'Roma%'
					then 'Roma'
				when residencia like 'sabinas%'
					then 'Hidalgo'
				when residencia like 'Houston' or residencia like 'Texas'
					then 'Texas'
				when residencia like 'Gexto'
					then 'Vizcaya'
				when residencia like 'Nuevo Laredo'
					then 'Tamaulipas'
				else null
			end as residencia_estado,
			case
				when residencia like 'Houston' or residencia like 'Estados Unidos'
					then 'Estados Unidos'
				when residencia like 'Gexto'
					then 'España'
				when residencia like 'Honduras'
					then residencia
				when residencia like 'Roma%'
					then 'Italia'
				when residencia like 'San Juan%'
					then 'Puerto Rico'
				else 'México'
			end as residencia_pais,
			case
				when residencia like 'Mty o Zona%' or residencia like 'Garc%'
					then 'Mty o Zona Metropolitana'
				when residencia like 'otro municipio%' or residencia like 'Nuevo León' or residencia like 'Linares'
					then 'Otro municipio NL'
				when residencia not like 'Mty o Zona%' and residencia not like 'Garc%' and residencia not like 'otro municipio%' and residencia not like 'Nuevo León' and residencia not like 'Linares' and residencia is not null
					then 'Foraneo'
			end as residencia_NL
		from tt01_pacientes
	) as i,
	(
		select ID_paciente,
			case
				when ocupacion like 'pension%' or ocupacion like 'jubil%'
					then 'Jubilado o Pensionado'
				when ocupacion like '%M%dico%'  or ocupacion like 'pedia%' or ocupacion like 'doct'
					then 'Medico'
				when ocupacion like 'abog%'
					then 'Abogado'
				when ocupacion like '%-%' or ocupacion like '%.%' or ocupacion is null or ocupacion like 'no %'
					then null
				when ocupacion like 'admin%'
					then 'Administrativo'
				when ocupacion like 'bienes%'
					then 'Bienes raíces'
				when ocupacion like 'ama de%' or ocupacion like 'espos%'  or ocupacion like 'hoga%'
					then 'Hogar'
				when ocupacion like 'cont%'
					then 'Contaduría'
				when ocupacion like 'desempl' or ocupacion like 'ning'
					then 'Desempleado'
				when ocupacion like 'maestr%'
					then 'Maestra'
				when ocupacion like 'niñ%de%años' or [ocupacion] like 'lactan%'
					then 'NA'
				when ocupacion like 'polic%'
					then 'Policía'
				when ocupacion like 'Tecnico'
					then 'Técnico'
				when ocupacion like 'vend%' or ocupacion like 'vent%'
					then 'Ventas'
				when ocupacion like 'empres%' or ocupacion like 'negocio%'
					then 'Empresario'
				when ocupacion like 'geren%'
					then 'Gerente'
				else ocupacion
			end as ocupacion
		from tt01_pacientes
	) as j,
	(
		select ID_paciente,
			case
				when registrador_paciente like 'Juan M%'
					then 'Juan Manuel'
				when registrador_paciente like 'Miguel%'
					then 'Miguel'
				when registrador_paciente like 'Sam%'
					then 'Samantha'
				when registrador_paciente like 'Steph%'
					then 'Stephanía'
				when registrador_paciente like 'sof%'
					then 'Sofia'
				when registrador_paciente like 'V%ctor%'
					then 'Víctor'
				when registrador_paciente like 'Laur%'
					then 'Laura'
				when registrador_paciente like 'Priscy%'
					then 'Priscyla'
				else registrador_paciente
			end as registrador_paciente
		from tt01_pacientes
	) as k
where a.ID_paciente = b.ID_paciente and a.ID_paciente = c.ID_paciente and a.ID_paciente = d.ID_paciente 
and a.ID_paciente = e.ID_paciente and a.ID_paciente = f.ID_paciente and a.ID_paciente = g.ID_paciente and a.ID_paciente = h.ID_paciente
and a.ID_paciente = i.ID_paciente and a.ID_paciente = j.ID_paciente and a.ID_paciente = k.ID_paciente
order by ID_paciente


select * from tt02_pacientes
where fecha_ingreso is null

-- Como hay nulos, vamos a asumir que la fecha de ingreso es la misma que la marca temporal.
drop table tt03_pacientes
select ID_paciente,
		case
			when fecha_ingreso is null
			then convert (date, marca_temporal, 23)
			else fecha_ingreso
		end as fecha_ingreso, 
		[hora_ingreso],	[marca_temporal], [sexo], [fecha_nacimiento], [edad_years], 
		[edad_meses], [peso_ingreso_kg], [talla_ingreso_cm], [estado_civil],
		[religion], [residencia_pais], [residencia_estado], [residencia_NL],
		[educacion], [ocupacion], [cuarto_cubiculo_actual], [diagnostico_paciente], 
		[hospital]
into tt03_pacientes
from tt02_pacientes

-- Solo falta cambiar el ID de la fecha de ingreso.

drop table tt04_pacientes
select a.ID_fecha, b.* 
into tt04_pacientes
from [dbo].[tt01_fechas] as a, tt03_pacientes as b
where a.fecha = b.fecha_ingreso 

------------------------------------------------------------------------------------
-- Ya, al fin. Tenemos una tabla limpia de registro de pacientes. TT04_pacientes
------------------------------------------------------------------------------------



select * from tt04_pacientes where ID_paciente in
(
select ID_paciente from [dbo].[tt02_4at_camicu]) and hospital is null

select * from tt02_pacientes where ID_paciente in
(
select ID_paciente from [dbo].[tt01_tamizaje]) and hospital is null



