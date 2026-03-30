import { run } from "uebersicht";

// Query the SQLite database for today and month usage
export const command = `
  DB="$HOME/Library/Group Containers/7PJ2KBXD4T.com.kidkuddy.internet-tracker.group/usage.db"
  if [ ! -f "$DB" ]; then
    DB="$HOME/Library/Application Support/InternetTracker/usage.db"
  fi
  if [ ! -f "$DB" ]; then
    echo '{"error":"no database"}'
    exit 0
  fi
  TODAY_START=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" +%s)
  MONTH_START=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-01) 00:00:00" +%s)
  TODAY=$(sqlite3 "$DB" "SELECT COALESCE(SUM(bytes_in),0)||'|'||COALESCE(SUM(bytes_out),0) FROM usage WHERE timestamp >= $TODAY_START;")
  MONTH=$(sqlite3 "$DB" "SELECT COALESCE(SUM(bytes_in),0)||'|'||COALESCE(SUM(bytes_out),0) FROM usage WHERE timestamp >= $MONTH_START;")
  echo "$TODAY||$MONTH"
`;

export const refreshFrequency = 10000; // 10 seconds

const formatBytes = (bytes) => {
  const b = Number(bytes);
  if (b >= 1099511627776) {
    const v = b / 1099511627776;
    return v >= 100 ? `${v.toFixed(0)} TB` : v >= 10 ? `${v.toFixed(1)} TB` : `${v.toFixed(2)} TB`;
  }
  if (b >= 1073741824) {
    const v = b / 1073741824;
    return v >= 100 ? `${v.toFixed(0)} GB` : v >= 10 ? `${v.toFixed(1)} GB` : `${v.toFixed(2)} GB`;
  }
  if (b >= 1048576) {
    const v = b / 1048576;
    return v >= 100 ? `${v.toFixed(0)} MB` : v >= 10 ? `${v.toFixed(1)} MB` : `${v.toFixed(2)} MB`;
  }
  if (b >= 1024) {
    const v = b / 1024;
    return v >= 100 ? `${v.toFixed(0)} KB` : v >= 10 ? `${v.toFixed(1)} KB` : `${v.toFixed(2)} KB`;
  }
  return `${b} B`;
};

export const className = `
  top: 20px;
  right: 20px;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", sans-serif;
  color: white;
  z-index: 1;

  .container {
    background: rgba(0, 0, 0, 0.55);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    padding: 18px 22px;
    min-width: 220px;
  }

  .header {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 14px;
    font-size: 12px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.5);
    letter-spacing: 0.5px;
  }

  .section {
    margin-bottom: 14px;
  }

  .section:last-of-type {
    margin-bottom: 0;
  }

  .label {
    font-size: 10px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.35);
    letter-spacing: 0.8px;
    text-transform: uppercase;
    margin-bottom: 4px;
  }

  .total {
    font-size: 26px;
    font-weight: 700;
    letter-spacing: -0.5px;
    margin-bottom: 4px;
  }

  .breakdown {
    display: flex;
    gap: 14px;
    font-size: 11px;
    font-weight: 500;
  }

  .down {
    color: #64b5f6;
  }

  .up {
    color: #ffb74d;
  }

  .arrow {
    font-size: 9px;
    font-weight: 800;
    margin-right: 3px;
  }

  .divider {
    height: 1px;
    background: rgba(255, 255, 255, 0.08);
    margin: 14px 0;
  }

  .error {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.4);
  }
`;

export const render = ({ output, error }) => {
  if (error || !output || output.includes("error")) {
    return (
      <div className="container">
        <div className="header">⟡ INTERNET</div>
        <div className="error">Waiting for data...</div>
      </div>
    );
  }

  const parts = output.trim().split("||");
  if (parts.length < 2) {
    return (
      <div className="container">
        <div className="header">⟡ INTERNET</div>
        <div className="error">No data yet</div>
      </div>
    );
  }

  const [todayIn, todayOut] = parts[0].split("|");
  const [monthIn, monthOut] = parts[1].split("|");
  const todayTotal = Number(todayIn) + Number(todayOut);
  const monthTotal = Number(monthIn) + Number(monthOut);

  return (
    <div className="container">
      <div className="header">⟡ INTERNET</div>

      <div className="section">
        <div className="label">Today</div>
        <div className="total">{formatBytes(todayTotal)}</div>
        <div className="breakdown">
          <span className="down"><span className="arrow">↓</span>{formatBytes(todayIn)}</span>
          <span className="up"><span className="arrow">↑</span>{formatBytes(todayOut)}</span>
        </div>
      </div>

      <div className="divider" />

      <div className="section">
        <div className="label">This Month</div>
        <div className="total">{formatBytes(monthTotal)}</div>
        <div className="breakdown">
          <span className="down"><span className="arrow">↓</span>{formatBytes(monthIn)}</span>
          <span className="up"><span className="arrow">↑</span>{formatBytes(monthOut)}</span>
        </div>
      </div>
    </div>
  );
};
