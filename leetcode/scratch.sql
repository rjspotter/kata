create table Sales(
sale_id int not null auto_increment primary key,
product_id int,
year int,
quantity int,
price int);

create table Product(
product_id int not null auto_increment primary key,
product_name varchar(256)
);

load data infile "/home/ubuntu/code/kata/leetcode/products.csv"
into table Product
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

load data infile "/home/ubuntu/code/kata/leetcode/sales.csv"
into table Sales
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';


insert into Sales (sale_id, product_id, year, quantity, price)
       values (1, 100, 2008, 10, 5000);

insert into Sales (sale_id, product_id, year, quantity, price)
       values (2, 100, 2009, 12, 5000);

insert into Sales (sale_id, product_id, year, quantity, price)
       values (7, 200, 2011, 15, 9000);

insert into Product (product_id, product_name)
       values (100, "Nokia");

insert into Product (product_id, product_name)
       values (200, "Apple");


select product_id, year as first_year, quantity, price from Sales group by product_id order by year;

select product_id, min(year) from Sales group by product_id;

select Sales.product_id, foo.first_year, quantity, price
from Sales inner join
(select product_id, min(year) as first_year from Sales group by product_id) as foo
on foo.product_id = Sales.product_id and foo.first_year = Sales.year;







