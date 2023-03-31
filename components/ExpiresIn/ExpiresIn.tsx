import React, { useState, useEffect } from 'react';

interface Props {
  blocks: number;
}

const ExpiresIn: React.FC<Props> = ({ blocks }) => {
  const [timeRemaining, setTimeRemaining] = useState(blocks * 12);

  useEffect(() => {
    setTimeRemaining(blocks * 12);

    const countdown = setInterval(() => {
      setTimeRemaining((prevTime) => Math.max(prevTime - 1, (blocks-1) * 12));
    }, 1000);

    // Cleanup interval when the component unmounts or blocks prop changes
    return () => {
      clearInterval(countdown);
    };
  }, [blocks]);

  return (
    <div>
      {blocks.toString() === "1" ? (
        <>
          Expires <strong>this block</strong> (~{timeRemaining} second{timeRemaining !== 1 && 's'}).
        </>
      ) : (
        <>
          Expires in <strong>{blocks} block{blocks !== 1 && 's'}</strong> (~{timeRemaining} second{timeRemaining !== 1 && 's'}).
        </>
      )}
    </div>
  );
};

export default ExpiresIn;
