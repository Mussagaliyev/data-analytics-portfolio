-- Задание 1. список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период;
SELECT 
  ID_client,
  COUNT(*) AS total_transactions,
  SUM(Sum_payment) AS total_amount,
  ROUND(AVG(Sum_payment), 2) AS avg_check,
  ROUND(SUM(Sum_payment) / 12, 2) AS avg_monthly_amount
FROM transactions 
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 13;

-- Задание 2. информацию в разрезе месяцев:
-- средняя сумма чека в месяц;
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  ROUND(AVG(Sum_payment), 2) AS avg_check
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month
ORDER BY month;

-- среднее количество операций в месяц;
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  ROUND(COUNT(*) / COUNT(DISTINCT ID_client), 2) AS avg_operations_per_client
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month
ORDER BY month;

-- среднее количество клиентов, которые совершали операции;
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  COUNT(DISTINCT ID_client) AS active_clients
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month
ORDER BY month;

-- долю от общего количества операций за год и долю в месяц от общей суммы операций;
SELECT 
  t1.month,
  ROUND(SUM(CASE WHEN t2.first_month = t1.month THEN 1 ELSE 0 END) / COUNT(*), 2) AS new_client_share_operations,
  ROUND(SUM(CASE WHEN t2.first_month = t1.month THEN t1.Sum_payment ELSE 0 END) / SUM(t1.Sum_payment), 2) AS new_client_share_revenue
FROM (
  SELECT *, DATE_FORMAT(date_new, '%Y-%m') AS month FROM transactions
) t1
JOIN (
  SELECT ID_client, MIN(DATE_FORMAT(date_new, '%Y-%m')) AS first_month
  FROM transactions
  GROUP BY ID_client
) t2 ON t1.ID_client = t2.ID_client
WHERE t1.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t1.month
ORDER BY t1.month;

-- вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
SELECT
  t1.month,
  c.Gender,
  ROUND(COUNT(*) * 100.0 / t2.total_ops, 2) AS op_share_pct,
  ROUND(SUM(t1.Sum_payment) * 100.0 / t2.total_sum, 2) AS revenue_share_pct
FROM (
  SELECT 
    ID_client,
    Sum_payment,
    DATE_FORMAT(date_new, '%Y-%m') AS month
  FROM transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
) t1
JOIN customers c ON t1.ID_client = c.ID_client
JOIN (
  SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(*) AS total_ops,
    SUM(Sum_payment) AS total_sum
  FROM transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
  GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) t2 ON t1.month = t2.month
GROUP BY t1.month, c.Gender
ORDER BY t1.month, c.Gender;

-- Задание 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

-- Общие показатели по возрастным группам
SELECT 
  CASE
      WHEN Age BETWEEN 0 AND 9 THEN '0-9'
      WHEN Age BETWEEN 10 AND 19 THEN '10-19'
      WHEN Age BETWEEN 20 AND 29 THEN '20-29'
      WHEN Age BETWEEN 30 AND 39 THEN '30-39'
      WHEN Age BETWEEN 40 AND 49 THEN '40-49'
      WHEN Age BETWEEN 50 AND 59 THEN '50-59'
      WHEN Age BETWEEN 60 AND 69 THEN '60-69'
      WHEN Age BETWEEN 70 AND 79 THEN '70-79'
      WHEN Age BETWEEN 80 AND 89 THEN '80-89'
    ELSE 'NA'
  END AS age_group,

  COUNT(*) AS transaction_count,
  SUM(t.Sum_payment) AS total_revenue,
  ROUND(AVG(t.Sum_payment), 2) AS avg_check

FROM customers c
JOIN transactions t ON c.ID_client = t.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group
ORDER BY 
  CASE 
    WHEN age_group = 'NA' THEN 999
    ELSE CAST(SUBSTRING_INDEX(age_group, '-', 1) AS UNSIGNED)
  END;

-- Поквартальный анализ по возрастным группам
SELECT 
  age_group,
  quarter,
  COUNT(*) AS transactions,
  SUM(Sum_payment) AS revenue,
  ROUND(AVG(Sum_payment), 2) AS avg_check,
  ROUND(SUM(Sum_payment) * 100.0 / SUM(SUM(Sum_payment)) OVER (PARTITION BY quarter), 2) AS revenue_pct,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY quarter), 2) AS transactions_pct
FROM (
  SELECT 
    CASE
      WHEN Age BETWEEN 0 AND 9 THEN '0-9'
      WHEN Age BETWEEN 10 AND 19 THEN '10-19'
      WHEN Age BETWEEN 20 AND 29 THEN '20-29'
      WHEN Age BETWEEN 30 AND 39 THEN '30-39'
      WHEN Age BETWEEN 40 AND 49 THEN '40-49'
      WHEN Age BETWEEN 50 AND 59 THEN '50-59'
      WHEN Age BETWEEN 60 AND 69 THEN '60-69'
      WHEN Age BETWEEN 70 AND 79 THEN '70-79'
      WHEN Age BETWEEN 80 AND 89 THEN '80-89'
      ELSE 'NA'
    END AS age_group,
    QUARTER(t.date_new) AS quarter,
    t.Sum_payment
  FROM transactions t
  JOIN customers c ON c.ID_client = t.ID_client
  WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
) AS sub
GROUP BY age_group, quarter
ORDER BY age_group, quarter;