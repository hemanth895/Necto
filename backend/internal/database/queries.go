package database

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID       int64
	Name     string
	Email    string
	Password string
	Role     string
}

func GetUserByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, name, email, password, role FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Name, &u.Email, &u.Password, &u.Role)
	return u, err
}

func UserExistsByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (bool, error) {
	var exists bool
	err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`, email).Scan(&exists)
	return exists, err
}

func CreateUser(ctx context.Context, pool *pgxpool.Pool, name, email, password, role string) (int64, error) {
	var id int64
	err := pool.QueryRow(ctx,
		`INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING id`,
		name, email, password, role,
	).Scan(&id)
	return id, err
}

func UpdateUserPassword(ctx context.Context, pool *pgxpool.Pool, email, password string) error {
	_, err := pool.Exec(ctx, `UPDATE users SET password = $1 WHERE email = $2`, password, email)
	return err
}

// Hospital profile
type HospitalProfile struct {
	ID             int64
	UserID         int64
	HospitalName   string
	Address        string
	Telephone      string
	ContactNumber  string
	Pincode        string
	HospitalImage  *string
	Verified       string
}

func GetHospitalProfileByUserID(ctx context.Context, pool *pgxpool.Pool, userID int64) (*HospitalProfile, error) {
	var h HospitalProfile
	err := pool.QueryRow(ctx,
		`SELECT id, user_id, hospital_name, address, telephone, contact_number, pincode, hospital_image, verified
		 FROM hospital_profiles WHERE user_id = $1`, userID,
	).Scan(&h.ID, &h.UserID, &h.HospitalName, &h.Address, &h.Telephone, &h.ContactNumber, &h.Pincode, &h.HospitalImage, &h.Verified)
	if err != nil {
		return nil, err
	}
	return &h, nil
}

func CreateHospitalProfile(ctx context.Context, pool *pgxpool.Pool, userID int64, name, address, telephone, contactNumber, pincode, imagePath string) (int64, error) {
	var id int64
	err := pool.QueryRow(ctx,
		`INSERT INTO hospital_profiles (user_id, hospital_name, address, telephone, contact_number, pincode, hospital_image, consent, verified)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,'yes','pending') RETURNING id`,
		userID, name, address, telephone, contactNumber, pincode, imagePath,
	).Scan(&id)
	return id, err
}

// Staff profile (minimal for checks)
func GetStaffProfileByUserID(ctx context.Context, pool *pgxpool.Pool, userID int64) (id int64, verified string, err error) {
	err = pool.QueryRow(ctx, `SELECT id, verified FROM staff_profiles WHERE user_id = $1`, userID).Scan(&id, &verified)
	return id, verified, err
}

type CreateStaffProfileParams struct {
	UserID              int64
	FullName             string
	Age                  int
	DOB                  string
	Gender               string
	Address              string
	Email                string
	Mobile               string
	EmergencyMobile      string
	Degree               string
	Stream               string
	OtherStream          *string
	College              string
	ExperienceYears      int
	CurrentInstitution   string
	WorkingRole          string
	WillingRoles         string
	PreferredLocation    string
	ProfilePhoto         *string
	Consent              string
}

func CreateStaffProfile(ctx context.Context, pool *pgxpool.Pool, p CreateStaffProfileParams) (int64, error) {
	var id int64
	err := pool.QueryRow(ctx,
		`INSERT INTO staff_profiles (user_id, full_name, age, dob, gender, address, email, mobile, emergency_mobile,
		 degree, stream, other_stream, college, experience_years, current_institution, working_role, willing_roles,
		 preferred_location, profile_photo, consent, verified)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,'no') RETURNING id`,
		p.UserID, p.FullName, p.Age, p.DOB, p.Gender, p.Address, p.Email, p.Mobile, p.EmergencyMobile,
		p.Degree, p.Stream, p.OtherStream, p.College, p.ExperienceYears, p.CurrentInstitution,
		p.WorkingRole, p.WillingRoles, p.PreferredLocation, p.ProfilePhoto, p.Consent,
	).Scan(&id)
	return id, err
}

// Hospital shift
func CreateHospitalShift(ctx context.Context, pool *pgxpool.Pool, hospitalID int64, hospitalName string, degree, stream, roleReq, shiftDate, startTime, endTime, lat, lng string, paymentAmount float64, paymentType, notes string) (int64, error) {
	var id int64
	err := pool.QueryRow(ctx,
		`INSERT INTO hospital_shifts (hospital_id, hospital_name, required_degree, required_stream, role_required,
		 shift_date, start_time, end_time, latitude, longitude, payment_amount, payment_type, notes, status)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,'open') RETURNING id`,
		hospitalID, hospitalName, degree, stream, roleReq, shiftDate, startTime, endTime, lat, lng, paymentAmount, paymentType, notes,
	).Scan(&id)
	return id, err
}

func GetHospitalShift(ctx context.Context, pool *pgxpool.Pool, shiftID, hospitalID int64) (degree, stream, shiftDate, startTime, endTime, lat, lng, status string, err error) {
	err = pool.QueryRow(ctx,
		`SELECT required_degree, required_stream, shift_date::text, start_time::text, end_time::text, latitude, longitude, status
		 FROM hospital_shifts WHERE id = $1 AND hospital_id = $2`,
		shiftID, hospitalID,
	).Scan(&degree, &stream, &shiftDate, &startTime, &endTime, &lat, &lng, &status)
	return degree, stream, shiftDate, startTime, endTime, lat, lng, status, err
}

// Staff availability
func CreateStaffAvailability(ctx context.Context, pool *pgxpool.Pool, staffID int64, state, district, taluka, workDate, startTime, endTime string, lat, lng float64) (int64, error) {
	var id int64
	err := pool.QueryRow(ctx,
		`INSERT INTO staff_availability (staff_id, state, district, taluka, work_date, start_time, end_time, latitude, longitude, status)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'available') RETURNING id`,
		staffID, state, district, taluka, workDate, startTime, endTime, lat, lng,
	).Scan(&id)
	return id, err
}

// Admin counts
func AdminGetCounts(ctx context.Context, pool *pgxpool.Pool) (staffCount, hospitalCount, pendingStaff, pendingHospital int64, err error) {
	_ = pool.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role = 'staff'`).Scan(&staffCount)
	_ = pool.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role = 'hospital'`).Scan(&hospitalCount)
	_ = pool.QueryRow(ctx, `SELECT COUNT(*) FROM staff_profiles WHERE verified = 'no'`).Scan(&pendingStaff)
	_ = pool.QueryRow(ctx, `SELECT COUNT(*) FROM hospital_profiles WHERE verified = 'pending'`).Scan(&pendingHospital)
	return staffCount, hospitalCount, pendingStaff, pendingHospital, nil
}

func AdminVerifyStaff(ctx context.Context, pool *pgxpool.Pool, profileID int64, approve bool, rejectionReason string) error {
	if approve {
		_, err := pool.Exec(ctx, `UPDATE staff_profiles SET verified = 'yes', rejection_reason = NULL WHERE id = $1`, profileID)
		return err
	}
	_, err := pool.Exec(ctx, `UPDATE staff_profiles SET verified = 'no', rejection_reason = $1 WHERE id = $2`, rejectionReason, profileID)
	return err
}

func AdminVerifyHospital(ctx context.Context, pool *pgxpool.Pool, profileID int64, approve bool, rejectionReason string) error {
	status := "no"
	if approve {
		status = "yes"
	}
	_, err := pool.Exec(ctx, `UPDATE hospital_profiles SET verified = $1 WHERE id = $2`, status, profileID)
	return err
}

// Admin list pending staff (verified != 'yes')
type PendingStaffRow struct {
	ProfileID         int64
	FullName          string
	Email             string
	Degree            string
	Stream            string
	ExperienceYears   int
	CurrentInstitution string
}

func AdminListPendingStaff(ctx context.Context, pool *pgxpool.Pool) ([]PendingStaffRow, error) {
	rows, err := pool.Query(ctx, `
		SELECT sp.id, sp.full_name, u.email, sp.degree, sp.stream, sp.experience_years, sp.current_institution
		FROM staff_profiles sp JOIN users u ON u.id = sp.user_id
		WHERE (sp.verified IS NULL OR sp.verified != 'yes') ORDER BY sp.id DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []PendingStaffRow
	for rows.Next() {
		var row PendingStaffRow
		if err := rows.Scan(&row.ProfileID, &row.FullName, &row.Email, &row.Degree, &row.Stream, &row.ExperienceYears, &row.CurrentInstitution); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

// Admin list pending hospitals (verified = 'pending')
type PendingHospitalRow struct {
	ID             int64
	HospitalName   string
	Email          string
	Telephone      string
	ContactNumber  string
	CreatedAt      string
}

func AdminListPendingHospitals(ctx context.Context, pool *pgxpool.Pool) ([]PendingHospitalRow, error) {
	rows, err := pool.Query(ctx, `
		SELECT hp.id, hp.hospital_name, u.email, hp.telephone, hp.contact_number, hp.created_at::text
		FROM hospital_profiles hp JOIN users u ON u.id = hp.user_id
		WHERE hp.verified = 'pending' ORDER BY hp.created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []PendingHospitalRow
	for rows.Next() {
		var row PendingHospitalRow
		if err := rows.Scan(&row.ID, &row.HospitalName, &row.Email, &row.Telephone, &row.ContactNumber, &row.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

// Available staff for a shift (join staff_availability + staff_profiles, haversine distance)
type AvailableStaffRow struct {
	AvailabilityID     int64
	StaffID            int64
	FullName           string
	Degree             string
	Specialization     string
	ExperienceYears    int
	CurrentInstitution string
	WorkingRole        string
	Latitude           float64
	Longitude          float64
	Distance           float64
	ProfilePhoto       *string
}

func GetAvailableStaffForShift(ctx context.Context, pool *pgxpool.Pool, shiftLat, shiftLng, degreeReq, streamReq, shiftDate, startTime, endTime string, radiusKm float64) ([]AvailableStaffRow, error) {
	rows, err := pool.Query(ctx, `
		SELECT sa.id AS availability_id, sa.staff_id, sp.full_name, sp.degree, sp.stream AS specialization,
		       sp.experience_years, sp.current_institution, sp.working_role, sa.latitude, sa.longitude, sp.profile_photo,
		       (6371 * acos(cos(radians($1::float)) * cos(radians(sa.latitude)) * cos(radians(sa.longitude) - radians($2::float)) + sin(radians($1::float)) * sin(radians(sa.latitude)))) AS distance
		FROM staff_availability sa
		JOIN staff_profiles sp ON sp.user_id = sa.staff_id
		WHERE sa.status = 'available' AND sp.degree = $3 AND sp.stream = $4 AND sp.verified = 'yes'
		  AND sa.work_date = $5::date AND sa.start_time <= $6::time AND sa.end_time >= $7::time
		  AND (6371 * acos(cos(radians($1::float)) * cos(radians(sa.latitude)) * cos(radians(sa.longitude) - radians($2::float)) + sin(radians($1::float)) * sin(radians(sa.latitude)))) <= $8
		ORDER BY distance ASC`,
		shiftLat, shiftLng, degreeReq, streamReq, shiftDate, startTime, endTime, radiusKm)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []AvailableStaffRow
	for rows.Next() {
		var row AvailableStaffRow
		if err := rows.Scan(&row.AvailabilityID, &row.StaffID, &row.FullName, &row.Degree, &row.Specialization,
			&row.ExperienceYears, &row.CurrentInstitution, &row.WorkingRole, &row.Latitude, &row.Longitude,
			&row.ProfilePhoto, &row.Distance); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}
