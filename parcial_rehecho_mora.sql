-- PARCIAL REHECHO

use `db_43493886_24062024`;
#1
-- Crear las tablas Provincias y Localidades con sus correspondientes columnas, primary keys, 
-- foreign keys (si correspondiera) y su vinculación con la tabla Personas.
-- Insertar la provincia de Santa Fe, la localidad de Rosario y asociar todos los clientes y 
-- proveedores a dicha localidad.


CREATE TABLE `db_43493886_24062024`.`provincias` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `provincia` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `db_43493886_24062024`.`localidades` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `localidad` VARCHAR(45) NOT NULL,
  `provincia_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_provincia_id_idx` (`provincia_id` ASC) VISIBLE,
  CONSTRAINT `fk_provincia_id`
    FOREIGN KEY (`provincia_id`)
    REFERENCES `db_43493886_24062024`.`provincias` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

INSERT INTO `db_43493886_24062024`.`provincias`(`provincia`)
VALUES("Santa Fe");

INSERT INTO `db_43493886_24062024`.`localidades`
(`localidad`,`provincia_id`)
VALUES("Rosario", last_insert_id());

select last_insert_id() into @localidad_id; -- agarro el ultimo id y lo guardo en localidad_id

ALTER TABLE `db_43493886_24062024`.`personas` 
CHANGE COLUMN `localidad_id` `localidad_id` INT NULL DEFAULT 1 ; -- creo el campo y lo seteo en 1

UPDATE `db_43493886_24062024`.`personas` SET`localidad_id` = @localidad_id; -- hago un update con el id 

ALTER TABLE `db_43493886_24062024`.`personas` -- hago la FK
ADD CONSTRAINT `fk_personas_localidades_id`
  FOREIGN KEY (`localidad_id`)
  REFERENCES `db_43493886_24062024`.`localidades` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

#2
-- Insertar en las tablas correspondientes la información relativa al cliente dando de alta tus datos personales (o inventados):
-- Nombre y apellido
-- Calle y nro - Localidad
-- Tipo doc. DNI y nro de DNI
-- Condición de IVA: COnsumidor Final
-- Teléfono

set @nro_doc="43493886";
set @tip_doc_ident_id=96; 
set @tip_doc_resp_id=5;
INSERT INTO `db_43493886_24062024`.`personas` -- primero tengo que hacer la tabla personas por la fk en nro_doc
(`nro_doc`,`nombre`,`apellido`,`razon_social`,`tip_doc_ident_id`,`tip_doc_resp_id`,`calle`,`altura`,`piso_dto_blk`,`localidad_id`)
VALUES
(@nro_doc,"Mora","Capdevila",null,@tip_doc_ident_id,@tip_doc_resp_id ,"Pellegrini","1876",null,@localidad_id);

SET @fec_nac = '2003-12-02';
INSERT INTO `db_43493886_24062024`.`clientes`
(`nro_doc`,`fec_nac`,`edad`,`telefono`,`celular`)
VALUES
(@nro_doc,@fec_nac,21,null,"3471620656");

#3
-- Insertar en las tablas correspondientes un ticket de compra con el siguiente detalle:
-- Cliente: insertado en el punto anterior
-- Fecha/Hora: la del momento
-- 2 azúcares
-- 1 yerba
-- Haz uso de variables para insertar el detalle del ticket, cálculos, etc.
-- Ayudín: primero insertar el ticket con importe total en 0, insertar los detalles del ticket, 
-- calcular el importe total a través de la suma de los importe parciales y actualizar el ticket.

set @ticket_id= last_insert_id();
INSERT INTO `db_43493886_24062024`.`tickets` -- primero el ticket con importe 0
(`id`,`cliente_id`,`fechora`,`importe_total`)
VALUES
(@ticket_id,@nro_doc,now(),0);

-- primero calculo el azucar
SET @producto_id=(SELECT id FROM db_43493886_24062024.productos where producto like "%Azúcar%" LIMIT 1); -- traigo el id
SET @precio = (select precio from db_43493886_24062024.precios where producto_id=@producto_id and fecha_vigencia <= now() order by fecha_vigencia DESC LIMIT 1); -- traigo el precio actualizado
set @cantidad=2; -- seteo cantidad
set @nro_correl=1; -- numero de linea del detalle del ticket

INSERT INTO `db_43493886_24062024`.`detallestickets` -- ahora hago el detalle del ticket para el azucar
(`ticket_id`,`nro_linea`,`cantidad`,`producto_id`,`importe_unitario`,`importe_parcial`)
VALUES
(@ticket_id,@nro_correl,@cantidad,@producto_id, @precio, @precio * @cantidad);

set @nro_correl=@nro_correl + 1; -- aumento el numero de linea
-- calculo lo de la yerba
SET @producto_id=(SELECT id FROM db_43493886_24062024.productos where producto like "%Yerba%" LIMIT 1);
SET @precio = (select precio from db_43493886_24062024.precios where producto_id=@producto_id and fecha_vigencia <= now() order by fecha_vigencia DESC LIMIT 1);
set @cantidad=1;

INSERT INTO `db_43493886_24062024`.`detallestickets` -- ahora hago el detalle del ticket para el azucar
(`ticket_id`,`nro_linea`,`cantidad`,`producto_id`,`importe_unitario`,`importe_parcial`)
VALUES
(@ticket_id,@nro_correl,@cantidad,@producto_id, @precio, @precio * @cantidad);

-- sumos los importes de cada detalle
SET @importe_total = (SELECT SUM(importe_parcial) FROM db_43493886_24062024.detallestickets where ticket_id = @ticket_id);

-- actualizo el importe total del ticket que habia puesto 0
UPDATE db_43493886_24062024.tickets SET importe_total=@importe_total where id = @ticket_id;


#4
-- Realizar un informe con el monto mínimo, el monto máximo y el valor del ticket promedio.
-- -------------------------------------------------------------------------------------
-- | Importe ticket menor monto | Importe ticket mayor monto | Importe ticket promedio |
-- -------------------------------------------------------------------------------------
-- | $xxxx.xx                   | $xxxx.xx                   | $xxxx.xx               |
-- -------------------------------------------------------------------------------------

select 
concat("$" ,  min(importe_total)) as "Importe ticket menor monto",
concat("$",  max(importe_total)) as "Importe ticket mayor monto",
concat("$" , avg(importe_total)) as "Importe ticñet promedio"
from db_43493886_24062024.tickets ;




#5
-- Informar los tickets cuyo importe total esté por encima del valor del ticket promedio.
-- -------------------------------------------------------------------------------------
-- | Nro de ticket | Nombre y apellido o Razón social | Fecha      | Importe total   |
-- -------------------------------------------------------------------------------------
-- | x             | xxxxxxxxxxxxxx                   | dd/mm/yyyy | $xxxx.xx        |
-- -------------------------------------------------------------------------------------
-- | x             | xxxxxxxxxxxxxx                   | dd/mm/yyyy | $xxxx.xx        |
-- -------------------------------------------------------------------------------------
-- 
-- 
-- -------------------------------------------------------------------------------------
-- | x             | xxxxxxxxxxxxxx                   | dd/mm/yyyy | $xxxx.xx        |
-- -------------------------------------------------------------------------------------

select T.id as "Nro de ticket", 
coalesce(P.razon_social, concat(P.nombre, " ", P.apellido)) as "Nombre y apellido o Razón Social",
date_format(T.fechora, "%d/%m/%y"),
concat("$", T.importe_total) as "Importe total"
from db_43493886_24062024.tickets T inner join db_43493886_24062024.personas P 
on T.cliente_id=P.nro_doc where T.importe_total>= (SELECT AVG(importe_total) FROM db_43493886_24062024.tickets) ORDER BY importe_total DESC;


#6
-- Informar los montos totales de los pedidos realizados a cada proveedor entre el 01/01/2023 y el 31/12/2023 
-- ordenadas por monto total en forma descendente.
-- -------------------------------------------------------------------------------------
-- | CUIT Proveedor | Nombre y apellido o Razón social | Monto total                 |
-- -------------------------------------------------------------------------------------
-- | xxxxxxxxxxx    | xxxxxxxxxxxxxx                   | $xxxx.xx                    |
-- -------------------------------------------------------------------------------------
-- | xxxxxxxxxxx    | xxxxxxxxxxxxxx                   | $xxxx.xx                    |
-- -------------------------------------------------------------------------------------
-- 
-- 
-- -------------------------------------------------------------------------------------
-- | xxxxxxxxxxx    | xxxxxxxxxxxxxx                   | $xxxx.xx                    |
-- -------------------------------------------------------------------------------------

-- P personas
-- PR proveedores
-- PE pedidos
select P.nro_doc as "CUIT Proveedor",
coalesce(P.razon_social, concat(P.nombre, " ", P.apellido)) as "Nombre y apellido o Razón Social",
concat("$", sum(PE.precio_uni_compra * PE.cantidad)) as "Monto total"
from db_43493886_24062024.pedidos PE inner join db_43493886_24062024.proveedores PR
on PE.nro_doc=PR.nro_doc inner join db_43493886_24062024.personas P on PR.nro_doc=P.nro_doc
where PE.fecha between "2023-01-01" and "2023-12-31" group by PR.nro_doc
order by "Monto total" desc;


#7
-- Mostrar la cantidad productos asociados a cada categoría, si una categoría no tuviera ningún producto 
-- asociado indicar 0, ordenar por cantidad en forma decreciente.
-- -------------------------------------------------------------------------------------
-- | Identificador | Categoría                         | Cantidad                      |
-- -------------------------------------------------------------------------------------
-- | 1             | xxxxxxxxxxxxxx                    | xx                            |
-- -------------------------------------------------------------------------------------
-- | 2             | xxxxxxxxxxxxxx                    | xx                            |
-- -------------------------------------------------------------------------------------
-- 
-- 
-- -------------------------------------------------------------------------------------
-- | n             | xxxxxxxxxxxxxx                    | 0                             |
-- -------------------------------------------------------------------------------------

-- cantidad de productos asociados a c/categoria (prod y categoria)
-- producto > id, producto, stock, umbral_stock, categoria_id
-- categoria > id, categoria
-- si cat tiene producto null = 0
-- order by cant desc

select C.id as "Identificador", -- es el de la categoria, no el del producto
C.categoria as "Categoria", -- el nombre
ifnull(count(P.id), 0) as "Cantidad" -- la cantidad cuenta la cantidad de id de esa categoria y si es nula pone 0
from db_43493886_24062024.categorias C left join -- hace el left para que tmb traiga los que son 0
db_43493886_24062024.productos P on C.id=P.categoria_id -- une 
group by C.id order by "Cantidad" desc; -- agrupa por el id de la categoria y ordena por la cantidad



