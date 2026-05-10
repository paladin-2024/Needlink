interface Props {
  size?: number
  className?: string
}

export default function NeedLinkLogo({ size = 32, className = '' }: Props) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className={className}
    >
      {/* Orange background */}
      <rect width="32" height="32" rx="8" fill="#EA580C" />
      {/* NL ligature mark — N's right leg becomes L's vertical, L arm extends right */}
      <polyline
        points="6,7 6,25 15,7 15,25 26,25"
        stroke="white"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
    </svg>
  )
}
