"use client";

import { useEffect, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { ImageField } from "@/components/image_field";
import { errorMessage } from "@/lib/api";

interface Localized {
  ku: string;
  ar: string;
  en: string;
}

export interface CourseRow {
  id: string;
  title: Localized;
  description: Localized;
  coverUrl: string | null;
  access: "free" | "paid";
  priceLabel: string;
  order: number;
}

type CoursePayload = Omit<CourseRow, "id">;

const createCourse = httpsCallable<CoursePayload, { courseId: string }>(functions, "admin-createCourse");
const updateCourse = httpsCallable<Partial<CoursePayload> & { courseId: string }, { ok: true }>(functions, "admin-updateCourse");
const deleteCourse = httpsCallable<{ courseId: string }, { ok: true; unlinkedEpisodes: number }>(functions, "admin-deleteCourse");

const EMPTY: Localized = { ku: "", ar: "", en: "" };
const LANGS = [
  { key: "ku", label: "Kurdish (کوردی)", dir: "rtl" },
  { key: "ar", label: "Arabic (العربية)", dir: "rtl" },
  { key: "en", label: "English", dir: "ltr" },
] as const;

/** Courses = named series of episodes (the Learn videos below), free or
 * paid. Paid courses show as Premium in the app with episode 1 as a free
 * preview; there is no payment yet. Reports the current list via
 * [onCourses] so the episode form can offer it. */
export function CourseManager({
  episodeCounts,
  onCourses,
}: {
  episodeCounts: Record<string, number>;
  onCourses: (courses: CourseRow[]) => void;
}) {
  const [courses, setCourses] = useState<CourseRow[] | null>(null);
  const [editing, setEditing] = useState<CourseRow | "new" | null>(null);
  const [title, setTitle] = useState<Localized>(EMPTY);
  const [description, setDescription] = useState<Localized>(EMPTY);
  const [coverUrl, setCoverUrl] = useState<string | null>(null);
  const [access, setAccess] = useState<"free" | "paid">("free");
  const [priceLabel, setPriceLabel] = useState("");
  const [order, setOrder] = useState("100");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(
    () =>
      onSnapshot(collection(db, "courses"), (snap) => {
        const l = (v: Partial<Localized> | undefined): Localized => ({ ku: v?.ku ?? "", ar: v?.ar ?? "", en: v?.en ?? "" });
        const rows = snap.docs
          .map((d) => {
            const x = d.data();
            return {
              id: d.id,
              title: l(x.title),
              description: l(x.description),
              coverUrl: (x.coverUrl as string | null) ?? null,
              access: (x.access === "paid" ? "paid" : "free") as "free" | "paid",
              priceLabel: (x.priceLabel as string) ?? "",
              order: (x.order as number) ?? 100,
            };
          })
          .sort((a, b) => a.order - b.order);
        setCourses(rows);
        onCourses(rows);
      }),
    [onCourses],
  );

  function open(course?: CourseRow) {
    setEditing(course ?? "new");
    setTitle(course?.title ?? EMPTY);
    setDescription(course?.description ?? EMPTY);
    setCoverUrl(course?.coverUrl ?? null);
    setAccess(course?.access ?? "free");
    setPriceLabel(course?.priceLabel ?? "");
    setOrder(String(course?.order ?? 100));
    setError(null);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (LANGS.some((l) => !title[l.key].trim() || !description[l.key].trim())) {
      return setError("Fill in the title and description in all three languages.");
    }
    const payload: CoursePayload = {
      title,
      description,
      coverUrl,
      access,
      priceLabel: access === "paid" ? priceLabel.trim() : "",
      order: Number.parseInt(order, 10) || 0,
    };
    setSaving(true);
    setError(null);
    try {
      if (editing === "new") await createCourse(payload);
      else if (editing) await updateCourse({ courseId: editing.id, ...payload });
      setEditing(null);
    } catch (err) {
      setError(errorMessage(err, "Couldn't save the course — try again."));
    } finally {
      setSaving(false);
    }
  }

  async function onDelete(c: CourseRow) {
    if (!window.confirm(`Delete course "${c.title.en}"? Its episodes are kept as quick videos.`)) return;
    try {
      await deleteCourse({ courseId: c.id });
    } catch (err) {
      setError(errorMessage(err, "Couldn't delete the course."));
    }
  }

  return (
    <section style={{ marginBottom: 32 }}>
      <div className="section-title" style={{ marginTop: 0 }}>
        Courses
        <button className="btn btn-ghost btn-sm" disabled={editing !== null} onClick={() => open()}>
          Add course
        </button>
      </div>

      {editing !== null && (
        <form className="panel stack" onSubmit={onSubmit} style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700 }}>{editing === "new" ? "New course" : "Edit course"}</div>
          {LANGS.map((l) => (
            <div className="field" key={`t-${l.key}`}>
              <label htmlFor={`course-title-${l.key}`}>Title — {l.label}</label>
              <input
                id={`course-title-${l.key}`}
                dir={l.dir}
                maxLength={120}
                value={title[l.key]}
                onChange={(e) => setTitle({ ...title, [l.key]: e.target.value })}
              />
            </div>
          ))}
          {LANGS.map((l) => (
            <div className="field" key={`d-${l.key}`}>
              <label htmlFor={`course-desc-${l.key}`}>Description — {l.label}</label>
              <textarea
                id={`course-desc-${l.key}`}
                dir={l.dir}
                rows={2}
                maxLength={2000}
                value={description[l.key]}
                onChange={(e) => setDescription({ ...description, [l.key]: e.target.value })}
              />
            </div>
          ))}
          <ImageField
            id="course-cover"
            label="Cover image (optional — otherwise the first episode's frame is used)"
            purpose="learn"
            value={coverUrl}
            onChange={setCoverUrl}
          />
          <div className="form-grid">
            <div className="field">
              <label htmlFor="course-access">Access</label>
              <select id="course-access" value={access} onChange={(e) => setAccess(e.target.value as "free" | "paid")}>
                <option value="free">Free — every episode plays</option>
                <option value="paid">Paid (Premium) — episode 1 is a free preview</option>
              </select>
            </div>
            <div className="field">
              <label htmlFor="course-price">Price label {access === "paid" ? "" : "(paid courses only)"}</label>
              <input
                id="course-price"
                maxLength={40}
                placeholder="e.g. $10 or 15,000 IQD"
                disabled={access !== "paid"}
                value={priceLabel}
                onChange={(e) => setPriceLabel(e.target.value)}
              />
            </div>
            <div className="field">
              <label htmlFor="course-order">Order (lower shows first)</label>
              <input id="course-order" type="number" min={0} value={order} onChange={(e) => setOrder(e.target.value)} />
            </div>
          </div>
          {access === "paid" && (
            <p className="muted" style={{ margin: 0, fontSize: 12.5 }}>
              There&apos;s no payment yet: the app shows Premium and &quot;coming soon&quot; on locked episodes.
            </p>
          )}
          {error && <p className="error-text">{error}</p>}
          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn btn-primary" type="submit" disabled={saving}>
              {saving ? "Saving…" : "Save course"}
            </button>
            <button className="btn btn-ghost" type="button" onClick={() => setEditing(null)}>
              Cancel
            </button>
          </div>
        </form>
      )}

      {editing === null && error && <p className="error-text">{error}</p>}

      {courses === null ? (
        <p className="muted">Loading…</p>
      ) : courses.length === 0 ? (
        <div className="empty-state">
          <strong>No courses yet</strong>
          Create a course, then add videos to it as episodes below.
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Course</th>
                <th>Episodes</th>
                <th>Access</th>
                <th className="num">Order</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {courses.map((c) => (
                <tr key={c.id}>
                  <td>
                    <div className="cell-media">
                      {c.coverUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={c.coverUrl} alt="" className="thumb" style={{ width: 64 }} />
                      ) : (
                        <div className="thumb thumb-empty" style={{ width: 64 }}>▶</div>
                      )}
                      <div>
                        <div className="cell-main">{c.title.en}</div>
                        <div className="cell-sub" dir="rtl" style={{ textAlign: "left" }}>
                          {c.title.ku} · {c.title.ar}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>{episodeCounts[c.id] ?? 0}</td>
                  <td>
                    <span className={`status ${c.access === "paid" ? "status-new" : "status-approved"}`}>
                      {c.access === "paid" ? `Premium${c.priceLabel ? ` · ${c.priceLabel}` : ""}` : "Free"}
                    </span>
                  </td>
                  <td className="num">{c.order}</td>
                  <td className="actions">
                    <button className="btn btn-ghost btn-sm" disabled={editing !== null} onClick={() => open(c)}>
                      Edit
                    </button>{" "}
                    <button className="btn btn-danger btn-sm" onClick={() => onDelete(c)}>
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {courses && courses.length > 0 && (
        <p className="muted" style={{ fontSize: 12.5, marginTop: 8 }}>
          The app only shows a course once it has at least one episode.
        </p>
      )}
    </section>
  );
}
