--EDA performed on Zomato Database to make insights.

--Create a table for users who signed up or availed Gold Membership 
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup
(userid integer,
gold_signup_date date); 

--Inserting values in goldusers_signup Table
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

--Create a table for All users 
drop table if exists users;
CREATE TABLE users
(userid integer,
signup_date date); 

--Insert Values in Table All Users
INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');


--Create a Sales Table
drop table if exists sales;
CREATE TABLE sales
(userid integer,
created_date date,
product_id integer); 

--Insert values in Sales Table
INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'22-09-2017',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

--Create a Product Table
drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

--Inserting values in Product Table
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;



--1. What is the Total Amount each customer spent on Zomato?

SELECT a.userid,SUM(b.price) Total_Amt_Spent
FROM sales a INNER JOIN product b
ON a.product_id = b.product_id 
GROUP BY a.userid

--2. How many days has each customer visited Zomato?

select userid, count(distinct created_Date)Total_Days from sales
group by userid;

--3. What was the first product purchased by each customer?
select a.* from
(select *,rank()over(partition by userid order by created_Date)rnk from sales)a
where a.rnk = 1

--4What is the most purchased item in the menu?

select Top 1 product_id, count(product_id) from sales
group by product_id
order by count(product_id) desc;

--5. How many times most purchased item was purchased by all the customers?

select userid,count(Product_id)cnt from sales where Product_id =
(select Top 1 product_id from sales
group by product_id
order by count(product_id) desc)
group by userid;

--6. Which Item was most popular for each customer?

select * from
(select *,rank()over(partition by userid order by cnt desc)rnk from
(select userid, product_id,count(product_id)cnt from sales
group by userid,product_id)a)b
where rnk=1


--Created Date : Order placed date and not user registration date on zomato 
--Gold Signup Date : Date on which user purchased Gold Membership

--7.which item first purchased by customer after they became prime member

select d.* from
(select c.*,rank()over(partition by userid order by created_date) rnk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date)c)d where rnk=1

--8. Which item was purchased just before the customer became the member

 select d.* from
(select c.*,rank()over(partition by userid order by created_date desc) rnk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date<=gold_signup_date)c)d where rnk=1

--9. Total Orders and Amount spent for each user before they became member?
 
select e.userid,count(e.created_date),sum(price) from
(select c.*,d.Price from 
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date<gold_signup_date)c
inner join product d
on c.Product_id = d.Product_id)e
group by userid

-- Points: For P1-On Spent of every 5Rs-customer will get 1 Zomato Point
--P2=10Rs=5 that means, on each 2RS,customer will get 1 Zomato Point
--P3=5Rs=1 Zomato Point
--Converted in 1 zomato point -> When we have total amount spent and amount of 1 zomato pt then we can easily calculate total points
--Total Points = Total Price/Price of each zomato point
--Calculate points collected by each customer and for which product most points have been given till now

select f.userid, sum(Total_Pts)Total_earned_points from
(select e.*, e.Price/e.Price_of_one_Zomato_point Total_Pts from
(select d.*, case when d.product_id = 1 then 5 when d.product_id =2 then 2 when d.product_id =3 then 5 else 0 end as Price_of_one_Zomato_point from 
(select c.userid, c.Product_id, sum(price) Price from
(select a.*,b.price from sales a inner join Product b
on a.product_id = b.product_id)c 
group by userid,product_id)d)e)f
group by userid


--If buying each product generates points for example : on every 5Rs = 2 zomato point --> 2.5 Rs. = 1 Zomato Point
select f.userid, sum(Total_Pts)*2.5 Total_earned_points from
(select e.*, e.Price/e.Price_of_one_Zomato_point Total_Pts from
(select d.*, case when d.product_id = 1 then 5 when d.product_id =2 then 2 when d.product_id =3 then 5 else 0 end as Price_of_one_Zomato_point from 
(select c.userid, c.Product_id, sum(price) Price from
(select a.*,b.price from sales a inner join Product b
on a.product_id = b.product_id)c
group by userid,product_id)d)e)f
group by userid


--Which Product most Points have been given till now
select * from
(select *, rank() over(order by Total_Points_earned desc)rnk from
(select f.product_id, sum(Total_Pts) Total_Points_earned from
(select e.*, e.Price/e.Points Total_Pts from
(select d.*, case when d.product_id = 1 then 5 when d.product_id =2 then 2 when d.product_id =3 then 5 else 0 end as Points from 
(select c.Product_id, sum(price) Price from
(select a.*,b.price from sales a inner join Product b
on a.product_id = b.product_id)c
group by product_id)d)e)f
group by product_id)g)h
where rnk=1;	

--In the First Year, after customer purchased Gold Membership(Including their join date) they will get 5 zomato points on every spent of 10Rs
--(1 Zomato Point = 2 Rs) and 1 Rs = 0.5 Zomato Points .So, Find Who earn more Userid 1 or Userid 3 ?
--To convert the Rs into Points, use 1 Rs = 0.5 Zomato Points 

select c.*,d.Price *0.5 Points from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date and created_date<= dateadd(year,1,gold_signup_date))c
inner join product d on c.product_id = d.product_id;

--Rank all the transactions of the customer

select *,rank()over(partition by userid order by created_date)rnk from sales;

--Rank all the transactions for each user whenever they are zomato gold member, and for every non gold member mark as NA

select d.*, case when rnk = 0 then 'NA' else rnk end as rnk from
(select c.*,cast((case when c.gold_signup_date is NULL then 0 else rank()over(partition by c.userid order by c.created_date desc)end) as varchar) rnk from
(Select a.userid,a.created_date,a.product_id,b.gold_signup_date from Sales a left join goldusers_signup b
on a.userid=b.userid and created_date>=gold_signup_date)c)d



 


