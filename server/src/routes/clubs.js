import { Router } from "express";
import { pool, withTransaction } from "../db.js";
import { HttpError, errorHandler } from "../http_error.js";
import { optionalAuth, requireAuth } from "../middleware/auth.js";

export const clubsRouter = Router();

export const CLUB_CATEGORIES = [
  "운동",
  "스터디",
  "음악",
  "미술/공예",
  "여행",
  "게임",
  "봉사활동",
  "기타",
];
const OPERATION_EXPERIENCES = [
  "NONE",
  "UNDER_ONE_YEAR",
  "ONE_TO_THREE_YEARS",
  "OVER_THREE_YEARS",
];

// 목록·상세에서 공통으로 쓰는 동호회 컬럼 (프론트 ClubSummary.fromJson 키에 맞춤)
const CLUB_COLUMNS = `
  c.id, c.name, c.category AS category_name, c.description, c.conditions,
  c.image_url, c.location_name, c.location_address, c.latitude, c.longitude,
  c.regular_meeting_info, c.max_members, c.created_at,
  (SELECT COUNT(*) FROM club_members cm
    WHERE cm.club_id = c.id AND cm.status = 'APPROVED') AS member_count`;

// ---------- 입력 검사 ----------

function parseId(value, message = "존재하지 않는 동호회입니다.") {
  const id = Number(value);
  if (!Number.isSafeInteger(id) || id <= 0) throw new HttpError(404, message);
  return id;
}

// 앞뒤 공백을 지운 문자열. 비어 있으면 null. 길이를 넘거나 필수인데 비면 400.
function text(value, { label, max, required = false }) {
  if (value === undefined || value === null) value = "";
  if (typeof value !== "string") {
    throw new HttpError(400, `${label}을(를) 확인해주세요.`);
  }
  const trimmed = value.trim();
  if (required && trimmed.length === 0) {
    throw new HttpError(400, `${label}을(를) 입력해주세요.`);
  }
  if (trimmed.length > max) {
    throw new HttpError(400, `${label}은(는) ${max}자 이하로 입력해주세요.`);
  }
  return trimmed.length === 0 ? null : trimmed;
}

function optionalNumber(value, { label, min, max }) {
  if (value === undefined || value === null || value === "") return null;
  const number = Number(value);
  if (!Number.isFinite(number) || number < min || number > max) {
    throw new HttpError(400, `${label}을(를) 확인해주세요.`);
  }
  return number;
}

// ---------- 공통 조회 ----------

async function findClub(db, clubId, { lock = false } = {}) {
  const [rows] = await db.query(
    `SELECT id, name, max_members, welcome_message FROM clubs WHERE id = ?
     ${lock ? "FOR UPDATE" : ""}`,
    [clubId],
  );
  if (rows.length === 0) throw new HttpError(404, "존재하지 않는 동호회입니다.");
  return rows[0];
}

async function findLeaderId(db, clubId) {
  const [rows] = await db.query(
    "SELECT user_id FROM club_leaders WHERE club_id = ?",
    [clubId],
  );
  return rows[0]?.user_id ?? null;
}

// 이 동호회의 회장인지 확인. 아니면 403.
async function assertLeaderOf(db, clubId, user, options) {
  const club = await findClub(db, clubId, options);
  if ((await findLeaderId(db, clubId)) !== user.id) {
    throw new HttpError(403, "동호회 회장만 할 수 있습니다.");
  }
  return club;
}

// 이 동호회의 승인된 부원(회장 포함)인지 확인. 아니면 403.
async function assertMemberOf(db, clubId, user) {
  const club = await findClub(db, clubId);
  const [rows] = await db.query(
    `SELECT id FROM club_members
     WHERE club_id = ? AND user_id = ? AND status = 'APPROVED'`,
    [clubId, user.id],
  );
  if (rows.length === 0) throw new HttpError(403, "동호회 부원만 볼 수 있습니다.");
  return club;
}

async function countMembers(db, clubId) {
  const [[row]] = await db.query(
    `SELECT COUNT(*) AS count FROM club_members
     WHERE club_id = ? AND status = 'APPROVED'`,
    [clubId],
  );
  return row.count;
}

async function notify(db, { userId, clubId, type, title, content }) {
  await db.query(
    `INSERT INTO notifications (user_id, club_id, type, title, content)
     VALUES (?, ?, ?, ?, ?)`,
    [userId, clubId, type, title, content],
  );
}

async function getClubDetail(clubId, user) {
  const [rows] = await pool.query(
    `SELECT ${CLUB_COLUMNS}, c.welcome_message,
       u.id AS leader_id, u.name AS leader_name, cl.leader_intro
     FROM clubs c
     LEFT JOIN club_leaders cl ON cl.club_id = c.id
     LEFT JOIN users u ON u.id = cl.user_id
     WHERE c.id = ?`,
    [clubId],
  );
  if (rows.length === 0) throw new HttpError(404, "존재하지 않는 동호회입니다.");
  const club = rows[0];

  // 내 상태: LEADER(이 동호회 회장) / PENDING / APPROVED / REJECTED / WITHDRAWN / null(신청 안 함)
  let myStatus = null;
  if (user) {
    if (club.leader_id === user.id) {
      myStatus = "LEADER";
    } else {
      const [members] = await pool.query(
        "SELECT status FROM club_members WHERE club_id = ? AND user_id = ?",
        [clubId, user.id],
      );
      myStatus = members[0]?.status ?? null;
    }
  }

  return { ...club, my_status: myStatus };
}

// ---------- 동호회 ----------

// 공개 동호회 목록. 카테고리와 검색어가 있으면 조건에 맞춰 최신순으로 반환합니다.
clubsRouter.get("/", async (request, response) => {
  if (
    (request.query.category !== undefined &&
      typeof request.query.category !== "string") ||
    (request.query.search !== undefined &&
      typeof request.query.search !== "string")
  ) {
    throw new HttpError(400, "검색 조건을 확인해주세요.");
  }
  const category =
    typeof request.query.category === "string"
      ? request.query.category.trim()
      : "";
  const search =
    typeof request.query.search === "string"
      ? request.query.search.trim()
      : "";

  if (category && !CLUB_CATEGORIES.includes(category)) {
    throw new HttpError(400, "지원하지 않는 카테고리입니다.");
  }
  if (search.length > 100) {
    throw new HttpError(400, "검색어는 100자 이하로 입력해주세요.");
  }

  const conditions = [];
  const parameters = [];
  if (category) {
    conditions.push("c.category = ?");
    parameters.push(category);
  }
  if (search) {
    const escapedSearch = search.replace(/[!%_]/g, "!$&");
    conditions.push(
      "(c.name LIKE ? ESCAPE '!' OR c.description LIKE ? ESCAPE '!' OR " +
        "c.category LIKE ? ESCAPE '!' OR c.location_name LIKE ? ESCAPE '!')",
    );
    const searchPattern = `%${escapedSearch}%`;
    parameters.push(searchPattern, searchPattern, searchPattern, searchPattern);
  }

  const whereClause =
    conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
  const [clubs] = await pool.query(
    `SELECT ${CLUB_COLUMNS}
     FROM clubs c
     ${whereClause}
     ORDER BY c.created_at DESC, c.id DESC`,
    parameters,
  );
  response.json({ clubs });
});

// 동호회 상세. 로그인했다면 my_status 로 가입 상태를 알려줍니다.
clubsRouter.get("/:clubId", optionalAuth, async (request, response) => {
  const club = await getClubDetail(parseId(request.params.clubId), request.user);
  response.json({ club });
});

// 동호회 개설: 회장만, 회장 1명당 1개
clubsRouter.post("/", requireAuth, async (request, response) => {
  if (request.user.role !== "LEADER") {
    throw new HttpError(403, "회장 회원만 동호회를 만들 수 있습니다.");
  }

  const body = request.body ?? {};
  const name = text(body.name, { label: "동호회 이름", max: 100, required: true });
  const description = text(body.description, { label: "소개글", max: 5000, required: true });
  const locationName = text(body.location_name, { label: "위치", max: 255, required: true });
  const locationAddress = text(body.location_address, { label: "주소", max: 500 });
  const conditions = text(body.conditions, { label: "가입 조건", max: 2000 });
  const imageUrl = text(body.image_url, { label: "이미지 주소", max: 2048 });
  const regularMeetingInfo = text(body.regular_meeting_info, { label: "정기 모임 정보", max: 255 });
  const welcomeMessage = text(body.welcome_message, { label: "가입 알람 메시지", max: 100 });
  const leaderIntro = text(body.leader_intro, { label: "한 줄 소개", max: 40 });
  const activityRegion = text(body.activity_region, { label: "활동 지역", max: 255 });
  const latitude = optionalNumber(body.latitude, { label: "위도", min: -90, max: 90 });
  const longitude = optionalNumber(body.longitude, { label: "경도", min: -180, max: 180 });

  if (!CLUB_CATEGORIES.includes(body.category)) {
    throw new HttpError(400, "카테고리를 선택해주세요.");
  }
  const maxMembers = Number(body.max_members);
  if (!Number.isInteger(maxMembers) || maxMembers < 1 || maxMembers > 1000) {
    throw new HttpError(400, "최대 인원은 1~1000명 사이로 입력해주세요.");
  }
  if ((latitude === null) !== (longitude === null)) {
    throw new HttpError(400, "위도와 경도를 함께 입력해주세요.");
  }
  const operationExperience = body.operation_experience ?? null;
  if (operationExperience !== null && !OPERATION_EXPERIENCES.includes(operationExperience)) {
    throw new HttpError(400, "운영 경험을 확인해주세요.");
  }

  const clubId = await withTransaction(async (db) => {
    // 같은 회장이 동시에 두 번 개설하지 못하도록 사용자 행을 잠급니다
    await db.query("SELECT id FROM users WHERE id = ? FOR UPDATE", [request.user.id]);
    const [leaders] = await db.query(
      "SELECT club_id FROM club_leaders WHERE user_id = ?",
      [request.user.id],
    );
    if (leaders[0]?.club_id) {
      throw new HttpError(409, "이미 운영 중인 동호회가 있습니다. 회장은 동호회를 하나만 만들 수 있어요.");
    }

    const [result] = await db.query(
      `INSERT INTO clubs (category, name, description, conditions, image_url,
         location_name, location_address, latitude, longitude,
         regular_meeting_info, max_members, welcome_message)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        body.category, name, description, conditions, imageUrl,
        locationName, locationAddress, latitude, longitude,
        regularMeetingInfo, maxMembers, welcomeMessage,
      ],
    );
    // 회장 가입 때 만든 프로필이 있으면 club_id 만 채우고, 없으면 새로 만듭니다
    await db.query(
      `INSERT INTO club_leaders (club_id, user_id, leader_intro, activity_region, operation_experience)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE club_id = VALUES(club_id), assigned_at = NOW()`,
      [result.insertId, request.user.id, leaderIntro, activityRegion, operationExperience],
    );
    // 회장도 부원 목록·인원 수에 포함되도록 승인된 부원으로 등록
    await db.query(
      `INSERT INTO club_members (club_id, user_id, status, decided_at)
       VALUES (?, ?, 'APPROVED', NOW())`,
      [result.insertId, request.user.id],
    );
    return result.insertId;
  });

  response.status(201).json({ club: await getClubDetail(clubId, request.user) });
});

// ---------- 가입 신청 ----------

// 가입 신청 (회원만). 거절·탈퇴했던 사람은 같은 행을 PENDING 으로 되돌려 재신청합니다.
clubsRouter.post("/:clubId/applications", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  const user = request.user;
  if (user.role === "LEADER") {
    throw new HttpError(403, "회장은 다른 동호회에 가입할 수 없습니다.");
  }
  const introduction = text(request.body?.introduction, { label: "한마디", max: 200 });

  await withTransaction(async (db) => {
    // 정원 확인과 신청이 동시에 일어나도 꼬이지 않도록 동호회 행을 잠급니다
    const club = await findClub(db, clubId, { lock: true });

    const [existing] = await db.query(
      "SELECT status FROM club_members WHERE club_id = ? AND user_id = ?",
      [clubId, user.id],
    );
    const status = existing[0]?.status;
    if (status === "PENDING") throw new HttpError(409, "이미 가입 신청했습니다.");
    if (status === "APPROVED") throw new HttpError(409, "이미 가입한 동호회입니다.");

    if ((await countMembers(db, clubId)) >= club.max_members) {
      throw new HttpError(409, "정원이 가득 찼습니다.");
    }

    await db.query(
      `INSERT INTO club_members (club_id, user_id, status, introduction)
       VALUES (?, ?, 'PENDING', ?)
       ON DUPLICATE KEY UPDATE status = 'PENDING', introduction = VALUES(introduction),
         applied_at = NOW(), decided_at = NULL`,
      [clubId, user.id, introduction],
    );

    const leaderId = await findLeaderId(db, clubId);
    if (leaderId) {
      await notify(db, {
        userId: leaderId,
        clubId,
        type: "JOIN_REQUESTED",
        title: "새 가입 신청",
        content: `${user.name}님이 ${club.name}에 가입 신청했어요.`,
      });
    }
  });

  response.status(201).json({ status: "PENDING" });
});

// 가입 신청 취소 (승인 대기 중일 때만)
clubsRouter.delete("/:clubId/applications/me", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  const [result] = await pool.query(
    `DELETE FROM club_members
     WHERE club_id = ? AND user_id = ? AND status = 'PENDING'`,
    [clubId, request.user.id],
  );
  if (result.affectedRows === 0) {
    throw new HttpError(404, "취소할 가입 신청이 없습니다.");
  }
  response.status(204).end();
});

// 가입 신청 목록 (회장만)
clubsRouter.get("/:clubId/applications", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  await assertLeaderOf(pool, clubId, request.user);

  const [applications] = await pool.query(
    `SELECT m.user_id, u.name, m.introduction, m.applied_at
     FROM club_members m
     JOIN users u ON u.id = m.user_id
     WHERE m.club_id = ? AND m.status = 'PENDING'
     ORDER BY m.applied_at`,
    [clubId],
  );
  response.json({ applications });
});

// 가입 승인 / 거절 (회장만). 결과는 신청자에게 알림으로 보냅니다.
async function decideApplication(request, response, approve) {
  const clubId = parseId(request.params.clubId);
  const applicantId = parseId(request.params.userId, "처리할 가입 신청이 없습니다.");

  await withTransaction(async (db) => {
    const club = await assertLeaderOf(db, clubId, request.user, { lock: true });

    const [rows] = await db.query(
      `SELECT id FROM club_members
       WHERE club_id = ? AND user_id = ? AND status = 'PENDING' FOR UPDATE`,
      [clubId, applicantId],
    );
    if (rows.length === 0) throw new HttpError(404, "처리할 가입 신청이 없습니다.");

    if (approve && (await countMembers(db, clubId)) >= club.max_members) {
      throw new HttpError(409, "정원이 가득 차서 승인할 수 없습니다.");
    }

    await db.query(
      "UPDATE club_members SET status = ?, decided_at = NOW() WHERE id = ?",
      [approve ? "APPROVED" : "REJECTED", rows[0].id],
    );
    await notify(db, {
      userId: applicantId,
      clubId,
      type: approve ? "JOIN_APPROVED" : "JOIN_REJECTED",
      title: `${club.name} 가입 ${approve ? "승인" : "거절"}`,
      content: approve
        ? club.welcome_message ?? `${club.name}에 가입되었어요!`
        : `아쉽지만 ${club.name} 가입 신청이 거절되었어요.`,
    });
  });

  response.json({ user_id: applicantId, status: approve ? "APPROVED" : "REJECTED" });
}

clubsRouter.post("/:clubId/applications/:userId/approve", requireAuth, (request, response) =>
  decideApplication(request, response, true),
);
clubsRouter.post("/:clubId/applications/:userId/reject", requireAuth, (request, response) =>
  decideApplication(request, response, false),
);

// ---------- 부원 ----------

// 부원 목록 (이 동호회 부원만 볼 수 있음). 회장이 맨 위.
clubsRouter.get("/:clubId/members", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  await assertMemberOf(pool, clubId, request.user);

  const [members] = await pool.query(
    `SELECT m.user_id, u.name, (cl.user_id IS NOT NULL) AS is_leader,
       COALESCE(m.decided_at, m.applied_at) AS joined_at
     FROM club_members m
     JOIN users u ON u.id = m.user_id
     LEFT JOIN club_leaders cl ON cl.club_id = m.club_id AND cl.user_id = m.user_id
     WHERE m.club_id = ? AND m.status = 'APPROVED'
     ORDER BY is_leader DESC, joined_at`,
    [clubId],
  );
  response.json({
    members: members.map((member) => ({ ...member, is_leader: Boolean(member.is_leader) })),
  });
});

// 동호회 탈퇴 (회장은 탈퇴 불가)
clubsRouter.delete("/:clubId/members/me", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  if ((await findLeaderId(pool, clubId)) === request.user.id) {
    throw new HttpError(403, "회장은 동호회를 탈퇴할 수 없습니다.");
  }

  const [result] = await pool.query(
    `UPDATE club_members SET status = 'WITHDRAWN', decided_at = NOW()
     WHERE club_id = ? AND user_id = ? AND status = 'APPROVED'`,
    [clubId, request.user.id],
  );
  if (result.affectedRows === 0) throw new HttpError(404, "가입한 동호회가 아닙니다.");
  response.status(204).end();
});

// 부원 내보내기 (회장만)
clubsRouter.delete("/:clubId/members/:userId", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  const memberId = parseId(request.params.userId, "해당 부원이 없습니다.");
  await assertLeaderOf(pool, clubId, request.user);
  if (memberId === request.user.id) {
    throw new HttpError(400, "회장은 내보낼 수 없습니다.");
  }

  const [result] = await pool.query(
    `UPDATE club_members SET status = 'WITHDRAWN', decided_at = NOW()
     WHERE club_id = ? AND user_id = ? AND status = 'APPROVED'`,
    [clubId, memberId],
  );
  if (result.affectedRows === 0) throw new HttpError(404, "해당 부원이 없습니다.");
  response.status(204).end();
});

// ---------- 공지 ----------

// 공지 목록 (이 동호회 부원만 볼 수 있음). 최신순.
clubsRouter.get("/:clubId/notices", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  await assertMemberOf(pool, clubId, request.user);

  const [notices] = await pool.query(
    `SELECT n.id, n.club_id, n.content, n.created_at,
       n.author_id, u.name AS author_name
     FROM club_notices n
     JOIN users u ON u.id = n.author_id
     WHERE n.club_id = ?
     ORDER BY n.created_at DESC, n.id DESC`,
    [clubId],
  );
  response.json({ notices });
});

// 공지 작성 (회장만). 회장을 뺀 승인된 부원 전원에게 NOTICE 알림을 보냅니다.
clubsRouter.post("/:clubId/notices", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  const content = text(request.body?.content, { label: "공지 내용", max: 500, required: true });

  const notice = await withTransaction(async (db) => {
    const club = await assertLeaderOf(db, clubId, request.user);
    const [result] = await db.query(
      "INSERT INTO club_notices (club_id, author_id, content) VALUES (?, ?, ?)",
      [clubId, request.user.id, content],
    );
    await db.query(
      `INSERT INTO notifications (user_id, club_id, type, title, content)
       SELECT user_id, club_id, 'NOTICE', ?, ?
       FROM club_members
       WHERE club_id = ? AND status = 'APPROVED' AND user_id <> ?`,
      [`${club.name} 공지`, content, clubId, request.user.id],
    );
    const [[row]] = await db.query(
      "SELECT id, club_id, content, created_at FROM club_notices WHERE id = ?",
      [result.insertId],
    );
    return row;
  });

  response.status(201).json({ notice });
});

// ---------- 모임 일정 ----------

// 월별 모임 일정 (누구나 조회). ?month=2026-10
clubsRouter.get("/:clubId/meetings", async (request, response) => {
  const clubId = parseId(request.params.clubId);
  const month = request.query.month;
  if (typeof month !== "string" || !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    throw new HttpError(400, "month 는 YYYY-MM 형식으로 보내주세요.");
  }
  await findClub(pool, clubId);

  const [meetings] = await pool.query(
    `SELECT id, meeting_at, place, memo FROM club_meetings
     WHERE club_id = ?
       AND meeting_at >= ? AND meeting_at < DATE_ADD(?, INTERVAL 1 MONTH)
     ORDER BY meeting_at`,
    [clubId, `${month}-01`, `${month}-01`],
  );
  response.json({ meetings });
});

// 모임 일정 등록 (회장만). meeting_at: 'YYYY-MM-DD HH:mm' 또는 'YYYY-MM-DDTHH:mm'
clubsRouter.post("/:clubId/meetings", requireAuth, async (request, response) => {
  const clubId = parseId(request.params.clubId);
  await assertLeaderOf(pool, clubId, request.user);

  const meetingAt = request.body?.meeting_at;
  if (
    typeof meetingAt !== "string" ||
    !/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?$/.test(meetingAt) ||
    Number.isNaN(Date.parse(meetingAt.replace(" ", "T")))
  ) {
    throw new HttpError(400, "모임 일시를 YYYY-MM-DD HH:mm 형식으로 보내주세요.");
  }
  const place = text(request.body?.place, { label: "장소", max: 255 });
  const memo = text(request.body?.memo, { label: "메모", max: 255 });

  const [result] = await pool.query(
    "INSERT INTO club_meetings (club_id, meeting_at, place, memo) VALUES (?, ?, ?, ?)",
    [clubId, meetingAt.replace("T", " "), place, memo],
  );
  const [[meeting]] = await pool.query(
    "SELECT id, meeting_at, place, memo FROM club_meetings WHERE id = ?",
    [result.insertId],
  );
  response.status(201).json({ meeting });
});

clubsRouter.use(errorHandler);
