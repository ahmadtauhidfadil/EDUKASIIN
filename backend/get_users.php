<?php
require_once 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$role = isset($_GET['role']) ? strtolower(trim($_GET['role'])) : '';
$query = isset($_GET['query']) ? trim($_GET['query']) : '';
$page = isset($_GET['page']) && is_numeric($_GET['page']) && (int) $_GET['page'] > 0 ? (int) $_GET['page'] : 1;
$limit = isset($_GET['limit']) && is_numeric($_GET['limit']) && (int) $_GET['limit'] > 0 ? min((int) $_GET['limit'], 50) : 10;
$offset = ($page - 1) * $limit;
$allowedRoles = ['admin', 'lansia', 'mentor'];
$conditions = [];
$params = [];
$types = '';

if ($role && in_array($role, $allowedRoles, true)) {
    $conditions[] = 'role = ?';
    $types .= 's';
    $params[] = $role;
}

if ($query !== '') {
    $conditions[] = '(name LIKE ? OR email LIKE ?)';
    $types .= 'ss';
    $params[] = "%{$query}%";
    $params[] = "%{$query}%";
}

$whereClause = '';
if (!empty($conditions)) {
    $whereClause = 'WHERE ' . implode(' AND ', $conditions);
}

try {
    $countSql = "SELECT COUNT(*) AS total FROM users {$whereClause}";
    $countStmt = $mysqli->prepare($countSql);
    if ($countStmt === false) {
        throw new Exception('Failed to prepare count');
    }
    if (!empty($params)) {
        $countStmt->bind_param($types, ...$params);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalCount = intval($countResult->fetch_assoc()['total'] ?? 0);
    $countStmt->close();

    $sql = "SELECT id, name, email, role FROM users {$whereClause} ORDER BY id DESC LIMIT ? OFFSET ?";
    $stmt = $mysqli->prepare($sql);
    if ($stmt === false) {
        throw new Exception('Failed to prepare query');
    }

    $bindTypes = $types . 'ii';
    $bindParams = array_merge($params, [$limit, $offset]);
    $stmt->bind_param($bindTypes, ...$bindParams);
    $stmt->execute();
    $result = $stmt->get_result();

    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'role' => $row['role'],
        ];
    }

    $stmt->close();

    $countByRole = [];
    $rolesStmt = $mysqli->prepare('SELECT role, COUNT(*) AS count FROM users GROUP BY role');
    if ($rolesStmt !== false) {
        $rolesStmt->execute();
        $rolesResult = $rolesStmt->get_result();
        while ($row = $rolesResult->fetch_assoc()) {
            $countByRole[strtolower($row['role'])] = intval($row['count']);
        }
        $rolesStmt->close();
    }

    echo json_encode([
        'status' => 'success',
        'data' => $users,
        'total_items' => $totalCount,
        'current_page' => $page,
        'per_page' => $limit,
        'has_more' => $offset + $limit < $totalCount,
        'counts' => [
            'lansia' => $countByRole['lansia'] ?? 0,
            'mentor' => $countByRole['mentor'] ?? 0,
            'admin' => $countByRole['admin'] ?? 0,
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Gagal memuat pengguna']);
}

$mysqli->close();
