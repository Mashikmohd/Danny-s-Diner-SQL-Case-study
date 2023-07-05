CREATE DATABASE IF NOT EXISTS dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);


CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);


CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
 /* What is the total amount each customer spent at the restaurant? */
  
select customer_id, sum(price) as total_spend
  from sales s
  join menu m 
  using(product_id)
  group by 1
  
/* How many days has each customer visited the restaurant? */

select customer_id, count(distinct order_date) as No_of_days_visited
from sales 
group by customer_id;

/* What was the first item from the menu purchased by each customer? */

with cte as (
select customer_id, product_name , order_date, dense_rank() over(partition by customer_id order by order_date) as rnk
from sales s
join menu m
using(product_id)
)
select customer_id, product_name
from cte
where rnk = 1
group by 1,2

/* What is the most purchased item on the menu and how many times was it purchased by all customers? */

select product_name, count(*) as quantity
from sales s
join menu m
using(product_id)
group by 1
order by 2 desc

/* Which item was the most popular for each customer? */

with cte as (
select customer_id, product_name, count(product_name) as quantity, 
dense_rank() over(partition by customer_id order by count(product_id) desc) as rnk
from sales s
join menu m
using(product_id)
group by 1,2
)
select customer_id, product_name 
from cte 
where rnk = 1

/* Which item was purchased first by the customer after they became a member? */

with cte as (
select customer_id, product_name, join_date, order_date, dense_rank() over(partition by customer_id order by order_date) as rnk
from sales s
join menu m
using(product_id)
join members ms
using(customer_id)
where order_date > join_date
)
select customer_id, product_name from cte 
where rnk = 1 


/* Which item was purchased just before the customer became a member? */

with cte as (
select customer_id, product_name, join_date, order_date, dense_rank() over(partition by customer_id order by order_date desc) as rnk
from sales s
join menu m
using(product_id)
join members ms
using(customer_id)
where order_date < join_date
)
select customer_id, product_name from cte 
where rnk = 1 

/* What is the total items and amount spent for each member before they became a member? */


select customer_id, count(product_id) as total_items , sum(price) as amount_spent
from sales s
join menu m
using(product_id)
join members ms
using(customer_id)
where order_date < join_date
group by 1


/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */

select customer_id, 
sum(case when product_name = 'sushi' then price* 20 else price * 10 end) as points
from sales s
join menu m
using(product_id)
group by 1
order by 2 desc

/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
 not just sushi - how many points do customer A and B have at the end of January? */
 
select customer_id, 
sum(case when order_date between join_date and DATE_ADD(join_date, INTERVAL 7 DAY) then price* 20 else price * 10 end) as points
from sales s
join menu m
using(product_id)
join members ms
using(customer_id)
where order_date <= '2021-01-31'
group by 1
order by 2 desc

/* Join All The Things recreate the table with: customer_id, order_date, product_name, price, member (Y/N), Ranking */

with cte as 
(select customer_id, order_date, product_name, price,
case 
when join_date <= order_date then 'Y'
when join_date > order_date then 'N'
else 'N' end as member
from sales s
left join menu m 
using(product_id)
left join members ms
using(customer_id) 
)
select customer_id, order_date, product_name, price, member, 
case 
when member = 'Y' then dense_rank() over(partition by customer_id,member order by order_date)
else null
end as ranking
from cte

