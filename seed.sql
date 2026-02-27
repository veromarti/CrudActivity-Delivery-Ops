 SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE order_items;
TRUNCATE payments;
TRUNCATE order_history;
TRUNCATE fulfillment;
TRUNCATE orders;
TRUNCATE products;
TRUNCATE categories;
TRUNCATE partners;
TRUNCATE clients;

SET FOREIGN_KEY_CHECKS = 1;
 
 INSERT INTO clients (full_name, email, status) VALUES
  ('Valentina Ríos',      'vale.rios@gmail.com',       'ACTIVE'),
  ('Sebastián Mora',      'sebas.mora@hotmail.com',    'ACTIVE'),
  ('Camila Herrera',      'cami.herrera@gmail.com',    'ACTIVE'),
  ('Andrés Castillo',     'andres.castillo@gmail.com', 'INACTIVE'),
  ('Luisa Fernanda Ruiz', 'luisa.ruiz@outlook.com',    'ACTIVE');


-- ============================================
-- PARTNERS (3)
-- ============================================

INSERT INTO partners (name, email, status) VALUES
  ('AgencyPro Studio',   'hola@agencypro.co',       'ACTIVE'),
  ('DigitalMind Labs',   'contact@digitalm.io',     'ACTIVE'),
  ('Nexo Consulting',    'ops@nexoconsulting.com',   'INACTIVE');


-- ============================================
-- CATEGORIES (5)
-- ============================================

INSERT INTO categories (name) VALUES
  ('Plantillas Notion'),
  ('Auditorías Digitales'),
  ('Mentorías'),
  ('Paquetes de Soporte'),
  ('Recursos Descargables');


-- ============================================
-- PRODUCTS (10)
-- ============================================
-- partner_id: 1=AgencyPro, 2=DigitalMind, 3=Nexo
-- category_id: 1=Notion, 2=Auditorías, 3=Mentorías, 4=Soporte, 5=Recursos

INSERT INTO products (name, description, price, stock, category_id, partner_id) VALUES
  ('Plantilla CRM Notion',         'Sistema CRM completo en Notion para equipos de ventas',         120000, 100, 1, 1),
  ('Plantilla OKR Trimestral',     'Framework de objetivos y resultados clave para equipos',         85000,  80,  1, 1),
  ('Auditoría SEO Básica',         'Revisión de 20 puntos clave de posicionamiento web',            250000,  30,  2, 2),
  ('Auditoría Redes Sociales',     'Análisis de presencia y estrategia en RRSS',                   180000,  25,  2, 2),
  ('Mentoría Estrategia Digital',  'Sesión 1:1 de 90 minutos con consultor senior',                350000,  15,  3, 2),
  ('Mentoría Productividad',       'Sesión de 60 minutos para optimizar flujos de trabajo',        200000,  20,  3, 1),
  ('Pack Soporte Básico',          '5 tickets de soporte técnico con respuesta en 24h',            300000,  40,  4, 3),
  ('Pack Soporte Premium',         '15 tickets prioritarios + onboarding call incluido',           750000,  15,  4, 3),
  ('Guía Marketing de Contenidos', 'PDF de 80 páginas con estrategia de contenido B2B',             60000, 200,  5, 1),
  ('Kit Branding Starter',         'Pack de recursos gráficos editables para marca personal',       95000, 150,  5, 2);


-- ============================================
-- ORDERS (8)
-- ============================================
-- client_id: 1=Valentina, 2=Sebastián, 3=Camila, 4=Andrés, 5=Luisa

INSERT INTO orders (client_id, status) VALUES
  (1, 'DELIVERED'),   -- order 1: Valentina, completado
  (2, 'PAID'),        -- order 2: Sebastián, pagado en proceso
  (3, 'IN_PROGRESS'), -- order 3: Camila, en progreso
  (1, 'CANCELED'),    -- order 4: Valentina, cancelado
  (5, 'DELIVERED'),   -- order 5: Luisa, completado
  (2, 'REFUNDED'),    -- order 6: Sebastián, reembolsado
  (3, 'CREATED'),     -- order 7: Camila, recién creado
  (4, 'PAID');        -- order 8: Andrés, pagado


-- ============================================
-- ORDER ITEMS (16)
-- ============================================

INSERT INTO order_items (order_id, product_id, quantity, unit_price, sub_total) VALUES
  -- Order 1: Valentina compra CRM Notion + Guía Marketing
  (1, 1,  1, 120000, 120000),
  (1, 9,  2,  60000, 120000),

  -- Order 2: Sebastián compra Auditoría SEO + Mentoría Estrategia
  (2, 3,  1, 250000, 250000),
  (2, 5,  1, 350000, 350000),

  -- Order 3: Camila compra Pack Soporte Premium + Kit Branding
  (3, 8,  1, 750000, 750000),
  (3, 10, 1,  95000,  95000),

  -- Order 4: Valentina (cancelada) intentó comprar OKR
  (4, 2,  1,  85000,  85000),

  -- Order 5: Luisa compra Auditoría RRSS + Mentoría Productividad + Guía
  (5, 4,  1, 180000, 180000),
  (5, 6,  1, 200000, 200000),
  (5, 9,  1,  60000,  60000),

  -- Order 6: Sebastián (reembolsado) compró Pack Soporte Básico
  (6, 7,  1, 300000, 300000),

  -- Order 7: Camila (recién creada) agrega CRM + OKR
  (7, 1,  1, 120000, 120000),
  (7, 2,  1,  85000,  85000),

  -- Order 8: Andrés compra Kit Branding + Guía Marketing
  (8, 10, 1,  95000,  95000),
  (8, 9,  3,  60000, 180000),
  (8, 6,  1, 200000, 200000);


-- ============================================
-- PAYMENTS (10)
-- incluye: reintentos, fallos y un solo aprobado por orden
-- ============================================

INSERT INTO payments (order_id, total, attempt, method, status) VALUES
  -- Order 1: fallo inicial, luego aprobado
  (1, 240000, 1, 'CREDIT',   'FAILED'),
  (1, 240000, 2, 'CREDIT',   'APPROVED'),

  -- Order 2: aprobado al primer intento
  (2, 600000, 1, 'TRANSFER', 'APPROVED'),

  -- Order 3: pendiente aún
  (3, 845000, 1, 'DEBIT',    'PENDING'),

  -- Order 4: cancelada, pago fallido
  (4,  85000, 1, 'DEBIT',    'FAILED'),

  -- Order 5: dos fallos, luego aprobado
  (5, 440000, 1, 'CREDIT',   'FAILED'),
  (5, 440000, 2, 'DEBIT',    'FAILED'),
  (5, 440000, 3, 'TRANSFER', 'APPROVED'),

  -- Order 6: aprobado y luego reembolsado (el pago quedó approved)
  (6, 300000, 1, 'CREDIT',   'APPROVED'),

  -- Order 8: aprobado directo
  (8, 475000, 1, 'TRANSFER', 'APPROVED');


-- ============================================
-- ORDER HISTORY
-- ============================================

INSERT INTO order_history (order_id, from_status, to_status) VALUES
  -- Order 1: CREATED → PAID → IN_PROGRESS → DELIVERED
  (1, 'CREATED',     'PAID'),
  (1, 'PAID',        'IN_PROGRESS'),
  (1, 'IN_PROGRESS', 'DELIVERED'),

  -- Order 2: CREATED → PAID
  (2, 'CREATED', 'PAID'),

  -- Order 3: CREATED → PAID → IN_PROGRESS
  (3, 'CREATED', 'PAID'),
  (3, 'PAID',    'IN_PROGRESS'),

  -- Order 4: CREATED → CANCELED (sin pago exitoso)
  (4, 'CREATED', 'CANCELED'),

  -- Order 5: flujo completo CREATED → DELIVERED
  (5, 'CREATED',     'PAID'),
  (5, 'PAID',        'IN_PROGRESS'),
  (5, 'IN_PROGRESS', 'DELIVERED'),

  -- Order 6: CREATED → PAID → REFUNDED
  (6, 'CREATED', 'PAID'),
  (6, 'PAID',    'REFUNDED'),

  -- Order 8: CREATED → PAID
  (8, 'CREATED', 'PAID');


-- ============================================
-- FULFILLMENT
-- ============================================

INSERT INTO fulfillment (order_id, status) VALUES
  (1, 'DONE'),
  (2, 'ASSIGNED'),
  (3, 'ASSIGNED'),
  (4, 'FAILED'),
  (5, 'DONE'),
  (6, 'FAILED'),
  (7, 'PENDING'),
  (8, 'ASSIGNED');