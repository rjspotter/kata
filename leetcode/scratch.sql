create table tree (
id int not null auto_increment primary key,
p_id int);

insert into tree (id) values (1);
insert into tree (id, p_id) values (2, 1);
insert into tree (id, p_id) values (3, 1);
insert into tree (id, p_id) values (4, 2);
insert into tree (id, p_id) values (5, 2);

select id,
case
    when p_id is null then "Root"
    when (select count(*) from tree as t2 where t2.p_id = tree.id) < 1 then "Leaf"
    else "Inner"
end as Type
from tree;




t
