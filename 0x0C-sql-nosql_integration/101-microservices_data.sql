/*
 * File: 101-microservices_data.sql
 * Description: Microservices Data Patterns and Database-per-Service Architecture
 * Author: Alpha0-1
 * 
 * This file demonstrates data management patterns for microservices architecture
 * including database-per-service, event-driven architecture, and data consistency patterns
 */

-- =============================================================================
-- SECTION 1: User Service Database
-- =============================================================================

/*
 * User Management Microservice
 * Handles user authentication, profiles, and account management
 */

-- User service database
CREATE SCHEMA IF NOT EXISTS user_service;
SET search_path TO user_service, public;

-- Core user entity
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    CONSTRAINT valid_status CHECK (status IN ('active', 'suspended', 'deleted'))
);

-- User profile information
CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    profile_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences and settings
CREATE TABLE user_preferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    preference_key VARCHAR(100) NOT NULL,
    preference_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, preference_key)
);

-- =============================================================================
-- SECTION 2: Product Service Database
-- =============================================================================

/*
 * Product Catalog Microservice
 * Manages product information, categories, and inventory
 */

CREATE SCHEMA IF NOT EXISTS product_service;
SET search_path TO product_service, public;

-- Product categories
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    parent_category_id UUID REFERENCES categories(category_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Core product entity
CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(category_id),
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    product_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    CONSTRAINT positive_price CHECK (price > 0),
    CONSTRAINT valid_status CHECK (status IN ('active', 'discontinued', 'out_of_stock'))
);

-- Product inventory management
CREATE TABLE inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    warehouse_location VARCHAR(100),
    quantity_available INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT non_negative_quantities CHECK (
        quantity_available >= 0 AND quantity_reserved >= 0
    )
);

-- =============================================================================
-- SECTION 3: Order Service Database
-- =============================================================================

/*
 * Order Management Microservice
 * Handles order processing, payment, and fulfillment
 */

CREATE SCHEMA IF NOT EXISTS order_service;
SET search_path TO order_service, public;

-- Orders table (contains minimal user reference)
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Reference to user service (no FK constraint)
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    shipping_address JSONB,
    billing_address JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    CONSTRAINT positive_amount CHECK (total_amount > 0),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- Order items
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL, -- Reference to product service (no FK constraint)
    product_sku VARCHAR(100) NOT NULL, -- Denormalized for performance
    product_name VARCHAR(255) NOT NULL, -- Denormalized for performance
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    
    CONSTRAINT positive_quantity CHECK (quantity > 0),
    CONSTRAINT positive_unit_price CHECK (unit_price > 0),
    CONSTRAINT valid_line_total CHECK (line_total = quantity * unit_price)
);

-- Order status history
CREATE TABLE order_status_history (
    status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by VARCHAR(100),
    change_reason TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- SECTION 4: Payment Service Database
-- =============================================================================

/*
 * Payment Processing Microservice
 * Handles payment transactions and billing
 */

CREATE SCHEMA IF NOT EXISTS payment_service;
SET search_path TO payment_service, public;

-- Payment methods
CREATE TABLE payment_methods (
    payment_method_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Reference to user service
    method_type VARCHAR(50) NOT NULL,
    provider VARCHAR(100) NOT NULL,
    external_id VARCHAR(255), -- ID from payment provider
    is_default BOOLEAN DEFAULT false,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_method_type CHECK (method_type IN ('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'digital_wallet'))
);

-- Payment transactions
CREATE TABLE payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL, -- Reference to order service
    user_id UUID NOT NULL, -- Reference to user service
    payment_method_id UUID REFERENCES payment_methods(payment_method_id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50) DEFAULT 'pending',
    provider_transaction_id VARCHAR(255),
    provider_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'))
);

-- =============================================================================
-- SECTION 5: Event Store for Microservices Communication
-- =============================================================================

/*
 * Event Sourcing and Message Passing
 * Central event store for microservices communication
 */

CREATE SCHEMA IF NOT EXISTS event_store;
SET search_path TO event_store, public;

-- Domain events table
CREATE TABLE domain_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_data JSONB NOT NULL,
    event_metadata JSONB,
    event_version INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(100),
    
    -- Ensure event ordering per aggregate
    UNIQUE(aggregate_type, aggregate_id, event_version)
);

-- Event subscriptions (which services listen to which events)
CREATE TABLE event_subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    endpoint_url VARCHAR(500) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(service_name, event_type)
);

-- Event processing log
CREATE TABLE event_processing_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES domain_events(event_id),
    service_name VARCHAR(100) NOT NULL,
    processing_status VARCHAR(50) DEFAULT 'pending',
    attempt_count INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_processing_status CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed', 'skipped'))
);

-- =============================================================================
-- SECTION 6: Saga Pattern Implementation
-- =============================================================================

/*
 * Distributed Transaction Management using Saga Pattern
 */

-- Saga instances
CREATE TABLE sagas (
    saga_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    saga_type VARCHAR(100) NOT NULL,
    saga_data JSONB NOT NULL,
    current_step INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_saga_status CHECK (status IN ('active', 'completed', 'failed', 'compensating'))
);

-- Saga steps definition
CREATE TABLE saga_steps (
    step_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    saga_id UUID REFERENCES sagas(saga_id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'command' or 'compensation'
    step_data JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    executed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_step_status CHECK (status IN ('pending', 'executing', 'completed', 'failed')),
    CONSTRAINT valid_action_type CHECK (action_type IN ('command', 'compensation')),
    UNIQUE(saga_id, step_order)
);

-- =============================================================================
-- SECTION 7: Cross-Service Data Synchronization
-- =============================================================================

/*
 * Data synchronization patterns for maintaining consistency
 */

-- Outbox pattern for reliable event publishing
CREATE TABLE outbox_events (
    outbox_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_attempts INTEGER DEFAULT 0,
    
    -- Index for efficient polling
    INDEX idx_outbox_unprocessed (created_at) WHERE processed_at IS NULL
);

-- Inbox pattern for idempotent event processing
CREATE TABLE inbox_events (
    inbox_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_status VARCHAR(50) DEFAULT 'pending',
    
    UNIQUE(event_id), -- Ensure idempotency
    CONSTRAINT valid_inbox_status CHECK (processing_status IN ('pending', 'processing', 'processed', 'failed'))
);

-- =============================================================================
-- SECTION 8: Service-Specific Views and Projections
-- =============================================================================

/*
 * Read models and projections for different services
 */

-- User service - user summary view
CREATE SCHEMA IF NOT EXISTS user_service_views;
SET search_path TO user_service_views, public;

CREATE MATERIALIZED VIEW user_summary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.status,
    up.first_name,
    up.last_name,
    u.created_at,
    COUNT(DISTINCT upr.preference_id) as preference_count
FROM user_service.users u
LEFT JOIN user_service.user_profiles up ON u.user_id = up.user_id
LEFT JOIN user_service.user_preferences upr ON u.user_id = upr.user_id
GROUP BY u.user_id, u.username, u.email, u.status, up.first_name, up.last_name, u.created_at;

-- Order service - order analytics view
CREATE SCHEMA IF NOT EXISTS order_service_views;
SET search_path TO order_service_views, public;

CREATE MATERIALIZED VIEW order_analytics AS
SELECT 
    o.user_id,
    COUNT(*) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    COUNT(CASE WHEN o.status = 'completed' THEN 1 END) as completed_orders,
    COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders
FROM order_service.orders o
GROUP BY o.user_id;

-- =============================================================================
-- SECTION 9: Microservices Integration Functions
-- =============================================================================

/*
 * Functions for handling cross-service operations
 */

-- Function to publish domain events
CREATE OR REPLACE FUNCTION publish_domain_event(
    p_event_type VARCHAR(100),
    p_aggregate_type VARCHAR(100),
    p_aggregate_id UUID,
    p_event_data JSONB,
    p_created_by VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    v_event_id UUID;
    v_event_version INTEGER;
BEGIN
    -- Get next version for this aggregate
    SELECT COALESCE(MAX(event_version), 0) + 1
    INTO v_event_version
    FROM event_store.domain_events
    WHERE aggregate_type = p_aggregate_type 
      AND aggregate_id = p_aggregate_id;
    
    -- Insert the event
    INSERT INTO event_store.domain_events (
        event_type, aggregate_type, aggregate_id, 
        event_data, event_version, created_by
    ) VALUES (
        p_event_type, p_aggregate_type, p_aggregate_id,
        p_event_data, v_event_version, p_created_by
    ) RETURNING event_id INTO v_event_id;
    
    -- Add to outbox for reliable delivery
    INSERT INTO outbox_events (
        aggregate_type, aggregate_id, event_type, event_data
    ) VALUES (
        p_aggregate_type, p_aggregate_id, p_event_type, p_event_data
    );
    
    RETURN v_event_id;
END;
$ LANGUAGE plpgsql;

-- Function to process saga compensation
CREATE OR REPLACE FUNCTION compensate_saga(p_saga_id UUID)
RETURNS BOOLEAN AS $
DECLARE
    v_step RECORD;
    v_success BOOLEAN := true;
BEGIN
    -- Update saga status to compensating
    UPDATE sagas 
    SET status = 'compensating', updated_at = NOW()
    WHERE saga_id = p_saga_id;
    
    -- Execute compensation steps in reverse order
    FOR v_step IN 
        SELECT * FROM saga_steps 
        WHERE saga_id = p_saga_id 
          AND action_type = 'compensation'
          AND status = 'completed'
        ORDER BY step_order DESC
    LOOP
        -- Here you would call the actual compensation service
        -- For now, we'll just mark it as executed
        UPDATE saga_steps 
        SET status = 'completed', executed_at = NOW()
        WHERE step_id = v_step.step_id;
    END LOOP;
    
    -- Mark saga as completed
    UPDATE sagas 
    SET status = 'completed', completed_at = NOW()
    WHERE saga_id = p_saga_id;
    
    RETURN v_success;
END;
$ LANGUAGE plpgsql;

-- =============================================================================
-- SECTION 10: Example Microservices Workflows
-- =============================================================================

/*
 * Example workflows demonstrating microservices data patterns
 */

-- Order placement workflow
CREATE OR REPLACE FUNCTION place_order_workflow(
    p_user_id UUID,
    p_order_items JSONB,
    p_shipping_address JSONB,
    p_payment_method_id UUID
)
RETURNS UUID AS $
DECLARE
    v_order_id UUID;
    v_saga_id UUID;
    v_total_amount DECIMAL(12,2) := 0;
    v_item JSONB;
BEGIN
    -- Calculate total amount
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_total_amount := v_total_amount + (v_item->>'quantity')::INTEGER * (v_item->>'unit_price')::DECIMAL;
    END LOOP;
    
    -- Create order
    INSERT INTO order_service.orders (
        user_id, order_number, total_amount, shipping_address
    ) VALUES (
        p_user_id, 
        'ORD-' || EXTRACT(EPOCH FROM NOW())::TEXT,
        v_total_amount,
        p_shipping_address
    ) RETURNING order_id INTO v_order_id;
    
    -- Create saga for distributed transaction
    INSERT INTO sagas (saga_type, saga_data) VALUES (
        'order_placement',
        jsonb_build_object(
            'order_id', v_order_id,
            'user_id', p_user_id,
            'payment_method_id', p_payment_method_id,
            'total_amount', v_total_amount
        )
    ) RETURNING saga_id INTO v_saga_id;
    
    -- Publish order created event
    PERFORM publish_domain_event(
        'OrderCreated',
        'Order',
        v_order_id,
        jsonb_build_object(
            'order_id', v_order_id,
            'user_id', p_user_id,
            'total_amount', v_total_amount,
            'saga_id', v_saga_id
        )
    );
    
    RETURN v_order_id;
END;
$ LANGUAGE plpgsql;

-- =============================================================================
-- SECTION 11: Sample Data and Testing
-- =============================================================================

/*
 * Sample data for testing microservices patterns
 */

-- Insert sample users
SET search_path TO user_service, public;
INSERT INTO users (username, email, password_hash) VALUES
('alice_johnson', 'alice@example.com', 'hashed_password_1'),
('bob_smith', 'bob@example.com', 'hashed_password_2'),
('carol_davis', 'carol@example.com', 'hashed_password_3');

-- Insert sample products
SET search_path TO product_service, public;
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Books', 'Physical and digital books'),
('Clothing', 'Apparel and accessories');

INSERT INTO products (sku, name, description, price) VALUES
('LAPTOP-001', 'Gaming Laptop', 'High-performance gaming laptop', 1299.99),
('BOOK-001', 'SQL Guide', 'Complete guide to SQL databases', 49.99),
('SHIRT-001', 'Cotton T-Shirt', 'Comfortable cotton t-shirt', 19.99);

-- Test event publishing
SELECT publish_domain_event(
    'UserRegistered',
    'User',
    (SELECT user_id FROM user_service.users WHERE username = 'alice_johnson'),
    '{"username": "alice_johnson", "email": "alice@example.com", "registration_source": "web"}'::jsonb,
    'system'
);

/*
 * Notes for Implementation:
 * 
 * 1. Database per Service:
 *    - Each microservice owns its data
 *    - No direct database access between services
 *    - Services communicate via events or APIs
 * 
 * 2. Data Consistency Patterns:
 *    - Eventual consistency between services
 *    - Saga pattern for distributed transactions
 *    - Event sourcing for audit and replay
 * 
 * 3. Communication Patterns:
 *    - Async messaging for non-critical operations
 *    - Sync calls for critical business operations
 *    - Event-driven architecture for loose coupling
 * 
 * 4. Monitoring and Observability:
 *    - Track saga execution and failures
 *    - Monitor event processing delays
 *    - Implement circuit breakers for service calls
 */
