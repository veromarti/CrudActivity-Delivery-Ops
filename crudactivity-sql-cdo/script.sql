CREATE DATABASE delivery_ops;

USE delivery_ops;

CREATE TABLE clients(
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  status ENUM ('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE' NOT NULL
);

CREATE TABLE partners(
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  status ENUM ('ACTIVE', 'INACTIVE') NOT NULL
);

CREATE TABLE products(
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(200) NOT NULL,
  price INT NOT NULL,
  stock INT NOT NULL,
  type INT NOT NULL,
  partner_id INT NOT NULL,
  
  CONSTRAINT
	FOREIGN KEY (partner_id) 
	REFERENCES partners(id) ON DELETE CASCADE
);

ALTER TABLE products
CHANGE type  category_id INT NOT NULL;

CREATE TABLE categories(
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

ALTER TABLE products
ADD CONSTRAINT FOREIGN KEY (category_id) 
	REFERENCES categories(id) ON DELETE CASCADE;

CREATE TABLE orders(
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  status ENUM ('CREATED', 'PAID', 'IN_PROGRESS', 'DELIVERED', 'CANCELED', 'REFUNDED') DEFAULT 'CREATED' NOT NULL,
  
  CONSTRAINT
	FOREIGN KEY (client_id) 
	REFERENCES clients(id)
);

CREATE TABLE order_items(
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price INT NOT NULL,
  sub_total INT NOT NULL,	
  
  FOREIGN KEY (product_id) 
	REFERENCES products(id),
  
  CONSTRAINT
	FOREIGN KEY (order_id) 
	REFERENCES orders(id) ON DELETE CASCADE
);

ALTER TABLE order_items
ADD PRIMARY KEY (order_id,product_id);

CREATE TABLE order_history(
  id INT AUTO_INCREMENT PRIMARY KEY,
  from_status ENUM ('CREATED', 'PAID', 'IN_PROGRESS', 'DELIVERED', 'CANCELED', 'REFUNDED') DEFAULT NULL,
  to_status ENUM ('CREATED', 'PAID', 'IN_PROGRESS', 'DELIVERED', 'CANCELED', 'REFUNDED','DELETED_ORDER') DEFAULT 'CREATED' NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  order_id INT NOT NULL,
  
  CONSTRAINT
    CHECK (from_status <> to_status),
  CONSTRAINT
	FOREIGN KEY (order_id) 
	REFERENCES orders(id)
);

CREATE TABLE payments(
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  total DECIMAL NOT NULL,
  attempt INT NOT NULL,
  method ENUM ('DEBIT', 'CREDIT', 'TRANSFER') NOT NULL,
  status ENUM ('PENDING', 'APPROVED', 'FAILED') DEFAULT 'PENDING' NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  
    
  CONSTRAINT
	FOREIGN KEY (order_id) 
	REFERENCES orders(id)
  );
  
ALTER TABLE payments
ADD COLUMN approved_anchor VARCHAR(10) 
  GENERATED ALWAYS AS (
    IF(status = 'APPROVED', 'APPROVED', NULL)
  ) STORED;
  
ALTER TABLE payments
ADD UNIQUE INDEX uq_one_approved_per_order (order_id, approved_anchor);

CREATE TABLE fulfillment(
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  status ENUM ('PENDING', 'ASSIGNED', 'DONE', 'FAILED') DEFAULT 'PENDING' NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  
 CONSTRAINT
	FOREIGN KEY (order_id) 
	REFERENCES orders(id)
  );
 
SHOW TABLES;

-- Ejecutar el archivo seeds.sql
 
SELECT COUNT(*) FROM clients;
SELECT COUNT(*) FROM partners;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM order_history;
SELECT COUNT(*) FROM fulfillment;

-- Resumen por pedido: order_id, customer, total_items, total_amount (Order + OrderItem + Customer)
SELECT * -- A la tabla orders le vamos a pegar informacion de la tabla donde vamos a buscar clientes
FROM orders;
JOIN clients ON clients.id = orders.client_id;
JOIN order_items ON order_id = orders.id;

SELECT  order_items.order_id, 
	SUM(order_items.quantity) AS total_items, 
	SUM(order_items.sub_total) AS total_amount -- Aqui esta el resumen de la compra pero falta la info del cliente
FROM order_items
GROUP BY order_items.order_id;


-- Consulta COMPLETA
SELECT orders.id AS order_id, 
	clients.full_name AS client,
	SUM(order_items.quantity) AS total_items, 
	SUM(order_items.sub_total) AS total_amount 
FROM orders
JOIN clients ON clients.id = orders.client_id
JOIN order_items ON order_items.order_id = orders.id
GROUP BY orders.id, clients.full_name
ORDER BY orders.id;

-- Top 3 productos más vendidos (por cantidad y por ingresos) (Product + OrderItem + Order)
SELECT *
FROM order_items;

SELECT order_items.product_id, 
	SUM(order_items.quantity) AS sold_quantity -- Aqui esta el resumen de los productos vendidos por cantidad falta info del producto
FROM order_items
GROUP BY order_items.product_id;

-- Consulta COMPLETA Top 3 productos mas vendidos por cantidad
SELECT  order_items.product_id,
	products.name AS product,
	SUM(order_items.sub_total) AS product_income,
	SUM(order_items.quantity) AS sold_quantity 
FROM order_items
JOIN products ON products.id = order_items.product_id
GROUP BY order_items.product_id
ORDER BY sold_quantity DESC LIMIT 3;

SELECT order_items.product_id, 
	SUM(order_items.quantity) AS sold_quantity -- Aqui esta el resumen de los productos vendidos por ingresos falta info del producto
FROM order_items
GROUP BY order_items.product_id;

-- Consulta COMPLETA Top 3 productos mas vendidos por ingresos
SELECT  order_items.product_id,
	products.name AS product,
	SUM(order_items.quantity) AS sold_quantity ,
	SUM(order_items.sub_total) AS product_income 
FROM order_items
JOIN products ON products.id = order_items.product_id
GROUP BY order_items.product_id
ORDER BY product_income DESC LIMIT 3;

-- Top 3 sellers por ingresos en pedidos pagados (pago aprobado) (Seller + Product + OrderItem + Payment)
SELECT *
FROM order_items;

SELECT  partners.name AS seller,
	SUM(order_items.sub_total) AS total_income 
FROM order_items
JOIN products ON products.id = order_items.product_id
JOIN partners ON partners.id = products.partner_id
GROUP BY order_items.product_id, partners.name;

-- CONSULTA COMPLETA
SELECT  
	partners.name AS seller,
	SUM(order_items.sub_total) AS total_income 
FROM order_items
JOIN payments ON payments.order_id = order_items.order_id
	AND payments.status = 'APPROVED'
JOIN orders ON orders.id = order_items.order_id
JOIN products ON products.id = order_items.product_id
JOIN partners ON partners.id = products.partner_id
GROUP BY partners.name;

-- Clientes frecuentes: customers con 2+ pedidos pagados y total gastado (Customer + Order + Payment + OrderItem)
SELECT * FROM clients;

SELECT clients.id,
	clients.full_name AS client,
	COUNT(DISTINCT orders.id) AS paid_orders
FROM clients
JOIN orders  ON orders.client_id = clients.id
JOIN payments ON payments.order_id = orders.id
    AND payments.status = 'APPROVED'
GROUP BY clients.id, clients.full_name;

-- Consulta completa
SELECT clients.id,
    clients.full_name AS client,
    COUNT(DISTINCT orders.id) AS paid_orders,
    SUM(order_items.sub_total) AS total_spent
FROM clients
JOIN orders  ON orders.client_id = clients.id
JOIN payments ON payments.order_id = orders.id
    AND payments.status = 'APPROVED'
JOIN order_items ON order_items.order_id = orders.id
GROUP BY clients.id, clients.full_name
HAVING 
    COUNT(DISTINCT orders.id) >= 2
ORDER BY 
    total_spent DESC;

-- Pedidos con inconsistencias:

-- pedidos en PAID sin pago aprobado
SELECT *
FROM orders;

SELECT 
    orders.id,
    orders.status
FROM orders;

SELECT orders.id,
    orders.status
FROM orders
JOIN payments ON payments.order_id = orders.id
AND payments.status = 'APPROVED';

SELECT orders.id,
    orders.status
FROM orders
LEFT JOIN payments ON payments.order_id = orders.id
AND payments.status = 'APPROVED';

SELECT orders.id,
    orders.status
FROM orders
LEFT JOIN payments 
    ON payments.order_id = orders.id
    AND payments.status = 'APPROVED'
WHERE orders.status = 'PAID'
AND payments.id IS NULL;

-- pedidos con pago aprobado pero status no corresponde (Order + Payment)
SELECT orders.id,
    orders.status,
    payments.status AS payment_status
FROM orders
JOIN payments ON payments.order_id = orders.id;

SELECT orders.id,
    orders.status,
    payments.status AS payment_status
FROM orders
JOIN payments ON payments.order_id = orders.id
WHERE payments.status = 'APPROVED';

SELECT orders.id,
    orders.status,
    payments.status AS payment_status
FROM orders
JOIN payments ON payments.order_id = orders.id
WHERE payments.status = 'APPROVED'
AND orders.status IN ('CREATED', 'CANCELED');

-- Último estado real de cada pedido usando OrderStatusHistory (no leyendo Order.status directamente)
SELECT oh.order_id,
    oh.to_status AS last_status
FROM order_history oh
JOIN (SELECT order_id,
        MAX(id) AS last_id
    FROM order_history
    GROUP BY order_id) latest ON latest.last_id = oh.id
ORDER BY oh.order_id;

-- Productos nunca vendidos (Product + OrderItem)
SELECT products.id,
    products.name
FROM products
LEFT JOIN order_items ON order_items.product_id = products.id
WHERE order_items.order_id IS NULL;

-- Promedio de ticket por categoría (promedio total por pedido asociado a categoría) (Category + Product + OrderItem + Payment)
SELECT 
    categories.name AS category,
    AVG(order_totals.order_total) AS avg_ticket
FROM (
    SELECT 
        orders.id AS order_id,
        SUM(order_items.sub_total) AS order_total
    FROM orders
    JOIN payments 
        ON payments.order_id = orders.id
        AND payments.status = 'APPROVED'
    JOIN order_items 
        ON order_items.order_id = orders.id
    GROUP BY orders.id
) order_totals
JOIN order_items 
    ON order_items.order_id = order_totals.order_id
JOIN products 
    ON products.id = order_items.product_id
JOIN categories 
    ON categories.id = products.category_id
GROUP BY categories.name
ORDER BY avg_ticket DESC;

-- Ranking mensual de clientes por gasto (mes-año, customer, total) (Customer + Order + Payment)
SELECT DATE_FORMAT(orders.created_at, '%Y-%m') AS date_year_month
FROM orders;

SELECT DATE_FORMAT(orders.created_at, '%Y-%m') AS date_year_month
FROM orders
JOIN clients ON clients.id = orders.client_id;

SELECT DATE_FORMAT(orders.created_at, '%Y-%m') AS date_year_month
FROM orders
JOIN clients ON clients.id = orders.client_id
JOIN payments ON payments.order_id = orders.id
AND payments.status = 'APPROVED';

SELECT DATE_FORMAT(orders.created_at, '%Y-%m') AS date_year_month,
	clients.full_name AS customer,
    SUM(payments.total) AS total_spent
FROM orders
JOIN clients ON clients.id = orders.client_id
JOIN payments ON payments.order_id = orders.id
AND payments.status = 'APPROVED'
GROUP BY 
	DATE_FORMAT(orders.created_at, '%Y-%m'),
    clients.id,
    clients.full_name;

SELECT 
    DATE_FORMAT(orders.created_at, '%Y-%m') AS date_year_month,
    clients.full_name AS customer,
    SUM(payments.total) AS total_spent
FROM orders
JOIN clients 
    ON clients.id = orders.client_id
JOIN payments 
    ON payments.order_id = orders.id
    AND payments.status = 'APPROVED'
GROUP BY 
    date_year_month,
    clients.id,
    clients.full_name
ORDER BY 
    date_year_month,
    total_spent DESC;

DESCRIBE orders;

-- Vista vw_order_summary:

-- order_id, customer_name, status, total_amount, approved_payment_date

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT 
    o.id AS order_id,
    c.full_name AS customer_name,
    o.status,
    SUM(oi.sub_total) AS total_amount, -- calcula el total real del pedido
    MAX(CASE 
            WHEN p.status = 'APPROVED' 
            THEN p.updated_at 
        END) AS approved_payment_date -- captura la fecha del pago aprobado (si existe)
FROM orders o
JOIN clients c 
    ON c.id = o.client_id
LEFT JOIN order_items oi -- permite mostrar pedidos aunque no tengan pago aprobado
    ON oi.order_id = o.id
LEFT JOIN payments p 
    ON p.order_id = o.id
GROUP BY 
    o.id, c.full_name, o.status;

-- Stored procedure

-- sp_register_payment(order_id, amount, method) que:

-- Inserte pago,
-- Valide “máximo 1 aprobado”,
-- Si aprueba: actualice estado del pedido + inserte historial.

DELIMITER $$

CREATE PROCEDURE sp_register_payment(
    IN p_order_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_method VARCHAR(50)
)
BEGIN

    DECLARE approved_count INT;

    -- Verificar si ya existe pago aprobado
    SELECT COUNT(*) INTO approved_count
    FROM payments
    WHERE order_id = p_order_id
      AND status = 'APPROVED';

    IF approved_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order already has an approved payment';
    END IF;

    -- Insertar pago aprobado
    INSERT INTO payments (order_id, total, attempt, method, status, created_at)
    VALUES (p_order_id, p_amount, 1, p_method, 'APPROVED', NOW());

    -- Actualizar estado del pedido
    UPDATE orders
    SET status = 'PAID'
    WHERE id = p_order_id;

    -- Insertar historial
    INSERT INTO order_history (order_id, from_status, to_status)
    VALUES (p_order_id, 'CREATED', 'PAID');

END $$

DELIMITER ;

CREATE INDEX idx_payments_order_status
ON payments (order_id, status);

CREATE INDEX idx_orders_client
ON orders (client_id);

