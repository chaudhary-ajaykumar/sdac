-- order_mangement

create database if not exists import_export_sdac ;
use import_export_sdac;

create table consumer_port(port_id  int  auto_increment primary key,password varchar(255) not null ,location varchar(255),role varchar(30) not null );

create table seller_port(port_id  int  auto_increment primary key,password varchar(255) not null ,location varchar(255),role varchar(30) not null );


create table products(product_id int auto_increment primary key,seller_port_id int ,foreign key (seller_port_id) references seller_port(port_id) ,product_name varchar(50)not null,quantity int,price double);


create table orders(order_id int auto_increment primary key ,product_id int ,consumer_port_id int ,seller_port_id int , foreign key (product_id) references products(product_id) , foreign key (consumer_port_id) references consumer_port(port_id) ,
foreign key (seller_port_id) references seller_port(port_id) ,quantity int not null ,order_date date ,order_placed boolean default true ,shipped boolean  default false,
out_for_delivery boolean default false,delivered boolean default false);

 
 
create table reported_products(report_id int auto_increment primary key,product_id int ,consumer_port_id int ,seller_port_id int , foreign key (product_id) references products(product_id) , foreign key (consumer_port_id) references consumer_port(port_id) ,
foreign key (seller_port_id) references seller_port(port_id) ,issue_type enum('Damage','Wrong Product','Delayed','Still Not Recieved') ,status enum('solved','pending') ,action_taken enum('replacement','compensation' ,'resend') ,report_date date);
 
 -- whrn order product available get less 
 delimiter &&
 create trigger trg_reduce_stock_after_order
 after insert on orders
 for each row
 begin 
  update products set quantity = quantity- new.quantity  where product_id = new.product_id;
  end &&
  delimiter 
 
 
 -- check id available qunatity is available and so user can place order 
delimiter &&
 create procedure place_order( o_product_id int)
 begin 
 if 
 end &&
 delimiter
 
 
 
 
 
