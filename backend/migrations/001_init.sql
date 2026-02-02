-- Necto backend - PostgreSQL schema (mirrors PHP app)

-- Users (login/register)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'hospital', 'staff')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Hospital profiles
CREATE TABLE IF NOT EXISTS hospital_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hospital_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    telephone VARCHAR(50) NOT NULL,
    contact_number VARCHAR(50) NOT NULL,
    pincode VARCHAR(20) NOT NULL,
    hospital_image VARCHAR(500),
    consent VARCHAR(10) DEFAULT 'yes',
    verified VARCHAR(20) DEFAULT 'pending' CHECK (verified IN ('pending', 'yes', 'no')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Staff profiles
CREATE TABLE IF NOT EXISTS staff_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    age INTEGER NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    email VARCHAR(255) NOT NULL,
    mobile VARCHAR(50) NOT NULL,
    emergency_mobile VARCHAR(50) NOT NULL,
    degree VARCHAR(100) NOT NULL,
    stream VARCHAR(100) NOT NULL,
    other_stream VARCHAR(255),
    college VARCHAR(255) NOT NULL,
    experience_years INTEGER NOT NULL,
    current_institution VARCHAR(255) NOT NULL,
    working_role VARCHAR(255) NOT NULL,
    willing_roles VARCHAR(255) NOT NULL,
    preferred_location VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(500),
    consent VARCHAR(10) DEFAULT 'yes',
    verified VARCHAR(20) DEFAULT 'no' CHECK (verified IN ('yes', 'no')),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Hospital shifts
CREATE TABLE IF NOT EXISTS hospital_shifts (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hospital_name VARCHAR(255) NOT NULL,
    required_degree VARCHAR(100) NOT NULL,
    required_stream VARCHAR(100) NOT NULL,
    role_required VARCHAR(255) NOT NULL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    latitude VARCHAR(50) NOT NULL,
    longitude VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL,
    payment_type VARCHAR(50) DEFAULT 'per_shift',
    notes TEXT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Staff availability (staff posts when they are available)
CREATE TABLE IF NOT EXISTS staff_availability (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    taluka VARCHAR(100) NOT NULL,
    work_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Shift requests (hospital sends request to staff for a shift)
CREATE TABLE IF NOT EXISTS shift_requests (
    id SERIAL PRIMARY KEY,
    shift_id INTEGER NOT NULL REFERENCES hospital_shifts(id) ON DELETE CASCADE,
    availability_id INTEGER NOT NULL REFERENCES staff_availability(id) ON DELETE CASCADE,
    staff_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hospital_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Staff notifications (admin/staff messages)
CREATE TABLE IF NOT EXISTS staff_notifications (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read VARCHAR(10) DEFAULT 'no' CHECK (is_read IN ('yes', 'no')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Hospital notifications
CREATE TABLE IF NOT EXISTS hospital_notifications (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read VARCHAR(10) DEFAULT 'no' CHECK (is_read IN ('yes', 'no')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Web push subscriptions (for push notifications)
CREATE TABLE IF NOT EXISTS web_push_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    p256dh TEXT NOT NULL,
    auth TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Staff phone verification (optional - for OTP)
CREATE TABLE IF NOT EXISTS staff_phone_verification (
    id SERIAL PRIMARY KEY,
    staff_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    verified VARCHAR(10) DEFAULT 'no' CHECK (verified IN ('yes', 'no')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_hospital_profiles_user_id ON hospital_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_user_id ON staff_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_hospital_shifts_hospital_id ON hospital_shifts(hospital_id);
CREATE INDEX IF NOT EXISTS idx_hospital_shifts_status ON hospital_shifts(status);
CREATE INDEX IF NOT EXISTS idx_staff_availability_staff_id ON staff_availability(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_availability_status ON staff_availability(status);
CREATE INDEX IF NOT EXISTS idx_shift_requests_shift_id ON shift_requests(shift_id);
