-- Add optional columns to shift_requests for distance and response tracking
ALTER TABLE shift_requests ADD COLUMN IF NOT EXISTS distance_km DECIMAL(8,2);
ALTER TABLE shift_requests ADD COLUMN IF NOT EXISTS responded_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE shift_requests ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Indexes for request lookups
CREATE INDEX IF NOT EXISTS idx_shift_requests_staff_id ON shift_requests(staff_id);
CREATE INDEX IF NOT EXISTS idx_shift_requests_hospital_id ON shift_requests(hospital_id);
CREATE INDEX IF NOT EXISTS idx_shift_requests_status ON shift_requests(status);
