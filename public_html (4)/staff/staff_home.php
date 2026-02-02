<h3>Post Your Availability</h3>

<form method="POST" action="staff_availability_action.php">

    <label>Date</label><br>
    <input type="date" name="available_date" required><br><br>

    <label>Time From</label><br>
    <input type="time" name="time_from" required><br><br>

    <label>Time To</label><br>
    <input type="time" name="time_to" required><br><br>

    <label>Location</label><br>
    <input type="text" name="location" placeholder="City / Area" required><br><br>

    <label>Status</label><br>
    <select name="status">
        <option value="available">Available</option>
        <option value="not_available">Not Available</option>
    </select><br><br>

    <button type="submit" class="btn">Post Availability</button>
</form>
